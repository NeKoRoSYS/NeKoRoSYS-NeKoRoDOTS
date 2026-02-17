#include <iostream>
#include <vector>
#include <string>
#include <cstring>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <thread>
#include <chrono>
#include <memory>
#include <cstdlib>
#include <cstdio>
#include <algorithm>
#include <set>

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

int parse_int_value(const std::string& json, size_t pos) {
    while (pos < json.length() && !isdigit(json[pos]) && json[pos] != '-') {
        pos++;
    }
    if (pos >= json.length()) return -999;
    return std::stoi(json.substr(pos));
}

bool is_waybar_visible = true;

void set_waybar(bool visible) {
    bool process_running = (system("pgrep -x waybar > /dev/null") == 0);

    if (visible) {
        if (!process_running) {
            system("waybar &");
            is_waybar_visible = true;
        } else if (!is_waybar_visible) {
            system("pkill -SIGUSR1 waybar");
            is_waybar_visible = true;
        }
    } else {
        if (process_running && is_waybar_visible) {
            system("pkill -SIGUSR1 waybar");
            is_waybar_visible = false;
        }
    }
}

void check_and_update() {
    std::string mon_out = exec("hyprctl -j monitors");
    std::set<int> active_workspace_ids;

    size_t pos = 0;
    while ((pos = mon_out.find("\"activeWorkspace\":", pos)) != std::string::npos) {
        size_t id_key = mon_out.find("\"id\":", pos);
        if (id_key != std::string::npos) {
            int id = parse_int_value(mon_out, id_key + 5);
            if (id != -999) active_workspace_ids.insert(id);
        }
        pos++;
    }

    if (active_workspace_ids.empty()) return;

    std::string clients_out = exec("hyprctl -j clients");
    bool has_windows = false;

    pos = 0;
    while ((pos = clients_out.find("\"workspace\":", pos)) != std::string::npos) {
        size_t id_key = clients_out.find("\"id\":", pos);
        if (id_key != std::string::npos) {
            int id = parse_int_value(clients_out, id_key + 5);
            if (active_workspace_ids.count(id)) {
                has_windows = true;
                break;
            }
        }
        pos++;
    }

    set_waybar(has_windows);
}

int main() {
    const char* runtime_dir = getenv("XDG_RUNTIME_DIR");
    const char* signature = getenv("HYPRLAND_INSTANCE_SIGNATURE");
    
    if (!runtime_dir || !signature) return 1;

    check_and_update();

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

    char buffer[4096];
    std::string pending_data = "";
    
    while (true) {
        ssize_t num_read = read(sfd, buffer, sizeof(buffer) - 1);
        if (num_read > 0) {
            buffer[num_read] = '\0';
            pending_data += buffer;
            
            size_t pos = 0;
            bool dirty = false;
            
            while ((pos = pending_data.find('\n')) != std::string::npos) {
                std::string line = pending_data.substr(0, pos);
                pending_data.erase(0, pos + 1);
                
                if (line.find("openwindow") == 0 ||
                    line.find("closewindow") == 0 ||
                    line.find("movewindow") == 0 ||
                    line.find("workspace") == 0 ||
                    line.find("focusedmon") == 0) {
                    dirty = true;
                }
            }
            
            if (dirty) {
                check_and_update();
            }
        } else if (num_read == -1) {
            std::this_thread::sleep_for(std::chrono::milliseconds(500));
        } else {
            break;
        }
    }

    close(sfd);
    return 0;
}
