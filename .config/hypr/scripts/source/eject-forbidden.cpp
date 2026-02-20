#include <iostream>
#include <string>
#include <vector>
#include <cstring>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <memory>
#include <cstdlib>
#include <cstdio>
#include <algorithm>

const std::vector<int> FORBIDDEN_IDS = {1}; 

struct PipeDeleter {
    void operator()(FILE* stream) const { if (stream) pclose(stream); }
};

std::string exec(const char* cmd) {
    char buffer[1024];
    std::string result = "";
    std::unique_ptr<FILE, PipeDeleter> pipe(popen(cmd, "r"));
    if (!pipe) return "";
    while (fgets(buffer, sizeof(buffer), pipe.get()) != nullptr) {
        result += buffer;
    }
    return result;
}

int get_active_window_workspace() {
    std::string json = exec("hyprctl -j activewindow");
    
    size_t ws_pos = json.find("\"workspace\":");
    if (ws_pos == std::string::npos) return -999;
    
    size_t id_pos = json.find("\"id\":", ws_pos);
    if (id_pos == std::string::npos) return -999;
    
    size_t start = id_pos + 5; 
    while (start < json.length() && !isdigit(json[start]) && json[start] != '-') start++;
    size_t end = start;
    while (end < json.length() && (isdigit(json[end]) || json[end] == '-')) end++;
    
    try {
        return std::stoi(json.substr(start, end - start));
    } catch (...) {
        return -999;
    }
}

void check_and_eject() {
    int ws_id = get_active_window_workspace();
    if (ws_id == -999) return;

    for (int forbidden : FORBIDDEN_IDS) {
        if (ws_id == forbidden) {
            system("hyprctl dispatch movetoworkspacesilent r+1 > /dev/null");
            return;
        }
    }
}

int main() {
    const char* runtime_dir = getenv("XDG_RUNTIME_DIR");
    const char* signature = getenv("HYPRLAND_INSTANCE_SIGNATURE");
    if (!runtime_dir || !signature) return 1;

    std::string socket_path = std::string(runtime_dir) + "/hypr/" + std::string(signature) + "/.socket2.sock";

    struct sockaddr_un addr;
    int sfd = socket(AF_UNIX, SOCK_STREAM, 0);
    if (sfd == -1) return 1;

    memset(&addr, 0, sizeof(struct sockaddr_un));
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, socket_path.c_str(), sizeof(addr.sun_path) - 1);

    if (connect(sfd, (struct sockaddr *) &addr, sizeof(struct sockaddr_un)) == -1) {
        close(sfd);
        return 1;
    }

    char buffer[1024];
    std::string pending_data = "";
    
    while (true) {
        ssize_t num_read = read(sfd, buffer, sizeof(buffer) - 1);
        if (num_read > 0) {
            buffer[num_read] = '\0';
            pending_data += buffer;
            
            size_t pos = 0;
            while ((pos = pending_data.find('\n')) != std::string::npos) {
                std::string line = pending_data.substr(0, pos);
                pending_data.erase(0, pos + 1);
                
                if (line.find("openwindow") == 0 || line.find("movewindow") == 0) {
                    check_and_eject();
                }
            }
        } else {
             break;
        }
    }

    close(sfd);
    return 0;
}
