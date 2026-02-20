#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <sstream>
#include <cstdio>
#include <memory>
#include <stdexcept>
#include <thread>
#include <chrono>
#include <cstdlib>
#include <algorithm>
#include <cstring> 

struct PipeDeleter {
    void operator()(FILE* stream) const {
        if (stream) pclose(stream);
    }
};

struct Monitor {
    int x, y, w, h;
};

struct Config {
    int activate_size = 10;
    int deactivate_size = 40;
    std::string bar_position = "top";
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

bool is_bar_visible = false; 

void toggle_waybar(bool visible) {
    if (visible != is_bar_visible) {
        system("pkill -SIGUSR1 waybar");
        is_bar_visible = visible;
    }
}

Config read_config() {
    Config cfg;
    const char* home_env = getenv("HOME");
    std::string home = home_env ? home_env : "";
    std::ifstream file(home + "/.cache/navbar-hover.conf");
    
    if (file.is_open()) {
        std::string line;
        while (getline(file, line)) {
            if (line.find("ACTIVATE_SIZE=") == 0) {
                try { cfg.activate_size = std::stoi(line.substr(14)); } catch (...) {}
            }
            if (line.find("DEACTIVATE_SIZE=") == 0) {
                try { cfg.deactivate_size = std::stoi(line.substr(16)); } catch (...) {}
            }
            if (line.find("BAR_POSITION=") == 0) {
                cfg.bar_position = line.substr(13);
                cfg.bar_position.erase(
                    std::remove(cfg.bar_position.begin(), cfg.bar_position.end(), '\"'),
                    cfg.bar_position.end()
                );
            }
        }
    }
    return cfg;
}

std::vector<Monitor> get_monitors() {
    std::vector<Monitor> monitors;
    std::string output = exec("hyprctl monitors -j | jq -r '.[] | \"\\(.x) \\(.y) \\(.width) \\(.height)\"'");
    std::stringstream ss(output);
    int x, y, w, h;
    while (ss >> x >> y >> w >> h) {
        monitors.push_back({x, y, w, h});
    }
    return monitors;
}

void wait_for_swaync() {
    while (true) {
        std::string layers = exec("hyprctl layers");
        
        if (layers.empty()) {
            std::this_thread::sleep_for(std::chrono::milliseconds(100));
            continue;
        }

        if (layers.find("swaync-control-center") != std::string::npos) {
            if (is_bar_visible) {
                toggle_waybar(false);
            }
            std::this_thread::sleep_for(std::chrono::milliseconds(150));
        } else {
            break;
        }
    }
}

int main() {
    wait_for_swaync();

    Config cfg = read_config();
    std::vector<Monitor> monitors = get_monitors();
    
    int cycle_count = 0;
    bool started_waybar = false;

    if (system("pgrep -x waybar >/dev/null") != 0) {
        system("waybar &");
        started_waybar = true;
        std::this_thread::sleep_for(std::chrono::milliseconds(200));
    }

    int retries = 0;
    const int max_retries = 50; 
    bool found_layer = false;

    while (retries < max_retries) {
        std::string layers = exec("hyprctl layers");
        
        if (layers.find("waybar") != std::string::npos) {
            is_bar_visible = true;
            found_layer = true;
            break;
        }

        if (!started_waybar && retries > 25) break; 
        
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
        retries++;
    }

    if (!found_layer && started_waybar) {
        is_bar_visible = true;
    }

    while (true) {
        wait_for_swaync();

        if (++cycle_count >= 50) {
            cfg = read_config();
            monitors = get_monitors();
            cycle_count = 0;
        }

        std::string pos_out = exec("hyprctl cursorpos");
        int cx = 0, cy = 0;
        
        if (sscanf(pos_out.c_str(), "%d, %d", &cx, &cy) == 2) {
            int thresh = is_bar_visible ? cfg.deactivate_size : cfg.activate_size;
            bool is_hovering = false;

            for (const auto& m : monitors) {
                bool match = false;
                if (cfg.bar_position == "top") {
                    match = (cx >= m.x && cx < m.x + m.w && cy >= m.y && cy <= m.y + thresh);
                } else if (cfg.bar_position == "bottom") {
                    match = (cx >= m.x && cx < m.x + m.w && cy >= m.y + m.h - thresh && cy <= m.y + m.h);
                } else if (cfg.bar_position == "left") {
                    match = (cx >= m.x && cx <= m.x + thresh && cy >= m.y && cy < m.y + m.h);
                } else if (cfg.bar_position == "right") {
                    match = (cx >= m.x + m.w - thresh && cx <= m.x + m.w && cy >= m.y && cy < m.y + m.h);
                }
                
                if (match) {
                    is_hovering = true;
                    break;
                }
            }

            if (is_hovering && !is_bar_visible) {
                toggle_waybar(true);
            } else if (!is_hovering && is_bar_visible) {
                toggle_waybar(false);
            }
        }

        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }

    return 0;
}
