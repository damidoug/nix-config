{ host, ... }:
{
  home-manager.users.${host.environment.user.username}.programs.mangohud = {
    enable = true;
    settings = {
      ### Performance
      fps_limit = 0; # 0 = unlimited; can be "60,144,0" to cycle

      ### GPU (AMD RX 580)
      gpu_stats = true;
      gpu_temp = true;
      gpu_core_clock = true;
      gpu_mem_clock = true; # needs vram enabled
      gpu_power = true;
      gpu_load_change = true;
      gpu_load_value = "60,90";
      gpu_load_color = "39F900,FDFD09,B22222";
      gpu_name = true;
      vram = true;

      ### CPU (Ryzen 5 2600)
      cpu_stats = true;
      cpu_temp = true;
      cpu_power = true;
      cpu_mhz = true;
      cpu_load_change = true;
      cpu_load_value = "60,90";
      cpu_load_color = "39F900,FDFD09,B22222";
      ram = true;

      ### Frame timing
      fps = true;
      frametime = true;
      frame_timing = true;
      fps_metrics = "avg,0.01"; # avg + 1% low
      throttling_status = true;

      ### Misc
      vulkan_driver = true;
      engine_version = true; # shows Proton/DXVK version
      resolution = true;

      ### Layout / appearance
      position = "top-left";
      font_size = 20;
      background_alpha = 0.4;
      round_corners = 8;
      text_outline = true;

      ### Keybinds
      toggle_hud = "Shift_R+F12";
      toggle_fps_limit = "Shift_L+F1";
      toggle_logging = "Shift_L+F2";
      reload_cfg = "Shift_L+F4";
    };
  };
}
