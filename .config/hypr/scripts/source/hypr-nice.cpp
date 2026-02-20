#include <iostream>
#include <vector>
#include <string>
#include <cstring>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <sys/resource.h> // Standard Linux header for setpriority
#include <memory>
#include <cstdlib>
#include <cstdio>
#include <algorithm>
#include <map>

struct PipeDeleter {
    void operator()(FILE* stream) const { if (stream) pclose(stream); }
};

std::string exec(const char* cmd) {
    char buffer[4096];
    std::string result = "";
    std::unique_ptr<FILE, PipeDeleter> pipe(popen(cmd, "r"));
    if (!pipe) return "";
    while (fgets(buffer, sizeof(buffer), pipe.get()) != nullptr) {
        result += buffer;
    }
    return result;
}

int get_json_int(const std::string& json, const std::string& key) {
    std::string search = "\"" + key + "\":";
    size_t pos = json.find(search);
    if (pos == std::string::npos) return -999;
    
    size_t start = pos + search.length();
    while (start < json.length() && (json[start] == ' ' || json[start] == '\n')) start++;
    
    size_t end = start;
    while (end < json.length() && (isdigit(json[end]) || json[end] == '-')) end++;
    
    try {
        return std::stoi(json.substr(start, end - start));
    } catch (...) {
        return -999;
    }
}

std::map<int, int> pid_priority_cache;

void update_priorities() {
    std::string ws_out = exec("hyprctl -j activeworkspace");
    int active_id = get_json_int(ws_out, "id");
    if (active_id == -999) return;

    std::string clients_out = exec("hyprctl -j clients");
    
    size_t cursor = 0;
    while ((cursor = clients_out.find("{", cursor)) != std::string::npos) {
        int depth = 1;
        size_t end = cursor + 1;
        while (end < clients_out.length() && depth > 0) {
            if (clients_out[end] == '{') depth++;
            else if (clients_out[end] == '}') depth--;
            end++;
        }
        
        std::string obj = clients_out.substr(cursor, end - cursor);
        
        int pid = get_json_int(obj, "pid");
        int ws_id = -999;
        size_t ws_block_pos = obj.find("\"workspace\":");
        if (ws_block_pos != std::string::npos) {
            ws_id = get_json_int(obj.substr(ws_block_pos), "id");
        }

        if (pid > 0 && ws_id != -999) {
            int target_prio = (ws_id == active_id) ? 0 : 19;
            
            if (pid_priority_cache.find(pid) == pid_priority_cache.end() || pid_priority_cache[pid] != target_prio) {
                setpriority(PRIO_PROCESS, pid, target_prio);
                pid_priority_cache[pid] = target_prio;
            }
        }
        cursor = end;
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

    update_priorities();

    char buffer[1024];
    std::string pending_data = "";
    
    while (true) {
        ssize_t num_read = read(sfd, buffer, sizeof(buffer) - 1);
        if (num_read > 0) {
            buffer[num_read] = '\0';
            pending_data += buffer;
            
            bool dirty = false;
            size_t pos = 0;
            while ((pos = pending_data.find('\n')) != std::string::npos) {
                std::string line = pending_data.substr(0, pos);
                pending_data.erase(0, pos + 1);
                
                if (line.find("workspace") == 0 || line.find("activewindow") == 0) {
                    dirty = true;
                }
            }
            if (dirty) update_priorities();
        } else {
            break;
        }
    }

    close(sfd);
    return 0;
}
