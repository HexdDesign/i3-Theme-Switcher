# UNDER CONSTRUCTION, DO NOT CLONE THIS REPO YET ! THANK YOU



# README ━━━


## ── ✦ . Arch i3 Theme Switcher . ✦ ──


Switch themes on i3 with this stunning collection of different high quality themes to choose from. :sparkles:


### ꩜ Dots by Dizzy ₊˚ʚ ᗢ₊˚✧ ﾟ.



>[!WARNING]
> Keep in mind that these dotfiles are coded for these options. ── Anything can be removed or replaced, in theory. The 'optional' section is just easier.

────────────────────────────

### REQUIRED
   - i3
   - Pacman
   - Polybar
   - Rofi
   - Eww
   - GTK 3.0
   - GTK 4.0
   - Thunar
   - Kitty
   - Neofetch
   - PulseAudio
   - Nmcli
   - Playerctl
   - Weather API
   - Geany
     
────────────────────────────
 
### OPTIONAL
   - Dunst
   - Picom
   - Feh
   - Nerd Fonts
   - Starship
   - i3lock-color
   - Firefox
   - Calcurse
 
────────────────────────────

>[!TIP]
>All of the files in this repo are to be loaded under your ~/.config/ folder!


## —— ⊹ i3 KEYBINDS ⊹ ——

**i3 Keybinds - They can be altered to your preferences in the config file:**

```
~/.config/i3/config 
```
   
- [Click to see i3's official site for more information about keybindings](https://i3wm.org/docs/userguide.html#_default_keybindings)

>[!NOTE]
>Keybind cheat sheet can be found within general file location in this repo as a text file by the name of - Keybind Cheat Sheet. However, here are some ones to note:

:star: Mod4: SUPER / WIN KEY  

### CUSTOM KEYBINDS:

━━ **i3 LOCK-COLOR** - Lock Screen:
```
 $mod+Shift+q
```
   
━━ **FLAMESHOT** - Screen Capture GUI:
```
 $mod+Shift+p
```
   
━━ **FIREFOX** - Default Browser:
```
 $mod+b
```

━━ **THUNAR** - File Manager:
```
$mod+m
```

━━ **i3 THEME SWITCHER:**
```
$mod+Shift+t
```


>[!TIP]
>File location cheat sheet can also be found in the general location in this repo as a text file by the name of - File Location.

────────────────────────────


:seedling: Some more important notes about this repo:


- Do not physically add files such as: current.conf, current.env, etc. symlink files. The theme switcher script will handle it.



:star: ROFI:

• app-launcher.rasi - This .rasi file is global for the application launcher.
 
• theme-picker.rasi - This .rasi file is global for the theme switcher.



:star: POLYBAR:

• BE CAREFUL as the EWW widgets are hard coded to desktop locations.
   
   ── Change their location in:
   ```
   ~/.config/eww/eww.yuck 
   ```

• MAKE SURE to input your own weather API into:
   ```
   ~/.config/polybar/scripts/weather.env
   ```

( Suggestion: Use OpenWeatherMap.org for free weather APIs ! )



:star: EWW:

• Sidebar - You can add your own quickapps to sidebar. 

   ── Add them in:
   ```
   ~/.config/eww/eww.yuck
   ```

   ── Then, be sure to create SVG icons accordingly and add them in:
   ```
    ~/.config/eww/icons/(name-of-theme)
   ```

   ── To change the size of quickapp icons, do so in:
   ```
   ~/.config/eww/yuck-themes/(name-of-theme)
   ```
    
( Change name-of-theme to the theme you would like to edit ! )

:star: THEME.ENV:

• The theme.env file within each:
   ```
   ~/.config/i3/(theme)
   ```

• Control file links here, as well as the colors for Dunst and i3 Lock-Color !



────────────────────────────

### CURRENT THEMES
   - Arch-Rain
   - Blue-Yellow
   - BRS (Black Rock Shooter)
   - Celty (Durarara)
   - Chill
   - Crimson
   - Devilman (Devilman Crybaby)
   - Dracula
   - Ember-Moon
   - ENA (Joel G.)
   - N7-Day (Mass Effect)
   - Neon-Violet
   - Nord
   - Sakura-Hunter (Monster Hunter)
     
────────────────────────────



────────────────────────────

## OFFICIAL DOCUMENTATIONS ・・・・・

>[!IMPORTANT]
>Please - review official documentions for accurate integrations and dependencies! Documentation file included in general location in this repo by the name of - Documentation.

:zap: 〢ARCH LINUX WIKI

[ARCH LINUX WIKI: INSTALLATION GUIDE](https://wiki.archlinux.org/title/Installation_guide)

[ARCH LINUX WIKI: i3 - Windows Manager](https://wiki.archlinux.org/title/I3)

[ARCH LINUX WIKI: PACMAN - Package Manager](https://wiki.archlinux.org/title/Pacman)

[ARCH LINUX WIKI: POLYBAR](https://wiki.archlinux.org/title/Polybar)

[ARCH LINUX WIKI: ROFI - Application Launcher](https://wiki.archlinux.org/title/Rofi)

[ARCH LINUX WIKI: GTK - GIMP Toolkit](https://wiki.archlinux.org/title/GTK)

[ARCH LINUX WIKI: THUNAR - Modern file manager for the Xfce Desktop Enviornment](https://wiki.archlinux.org/title/Thunar)

[ARCH LINUX WIKI: KITTY - Terminal Emulator](https://wiki.archlinux.org/title/Kitty) 

[ARCH LINUX WIKI: PULSEAUDIO - Network-Capable Sound Server](https://wiki.archlinux.org/title/PulseAudio)

[ARCH LINUX WIKI: NMCLI - Network Configuration / Wireless](https://wiki.archlinux.org/title/NetworkManager)

[ARCH LINUX WIKI: Network Configuration / Wireless](https://wiki.archlinux.org/title/Network_configuration/Wireless)

[ARCH LINUX WIKI: BLUETOOTH](https://wiki.archlinux.org/title/Bluetooth)

[ARCH LINUX WIKI: XDG - Desktop Portal](https://wiki.archlinux.org/title/XDG_Desktop_Portal)

[ARCH LINUX WIKI: DUNST - Notification Daemon](https://wiki.archlinux.org/title/Dunst)

[ARCH LINUX WIKI: FEH - Image Viewer](https://wiki.archlinux.org/title/Feh)

[ARCH LINUX WIKI: PICOM - Standalone Compositor for Xorg](https://wiki.archlinux.org/title/Picom)



:zap: 〢GITHUB

[GITHUB REPO: EWW - Wacky Widgets](https://github.com/elkowar/eww)

[GITHUB REPO: EWW - Wacky Widgets](https://elkowar.github.io/eww/)

[GITHUB REPO: NEOFETCH - A Command-Line System Information Tool](https://github.com/dylanaraps/neofetch)

[GITHUB REPO: CALCURSE - A Text-Based Calendar and Scheduling Application](https://github.com/lfos/calcurse)

[GITHUB REPO: PLAYERCTL - Mpris Media Player Command-Line Controller](https://github.com/altdesktop/playerctl)

[GITHUB REPO: i3LOCK-COLOR](https://github.com/Raymo111/i3lock-color)

[GITHUB REPO: STARSHIP - Customizable Prompt](https://github.com/starship/starship)



:zap: 〢OTHER

[OPEN WEATHER MAP: WEATHER APIs](https://openweathermap.org/api)
    ᯓ➤ OR: Another way to generate a weather API ✶


[NERD FONTS](https://www.nerdfonts.com/)


[GEANY: Text Editor](https://www.geany.org/)


[FIREFOX: Color](https://color.firefox.com/)


[GTK ICONS: Gnome-Look](https://www.gnome-look.org/)



:sparkles: 〢GTK ICONS

[Dexy-Color-Dark-Icons](https://www.gnome-look.org/p/1964004)


[Nordzy](https://www.gnome-look.org/p/1686927)


[Tela-Circle](https://www.gnome-look.org/p/1359276)


[Papirus](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme)


[Goldy-Dark-Icons](https://www.gnome-look.org/p/2037378)


[Vivid-Glassy-Dark-Icons](https://www.gnome-look.org/p/2119129/)


[Fluent-Icon-Theme](https://www.gnome-look.org/p/1477945)


[Slot-Silvery-Dark-Icons](https://www.gnome-look.org/p/2344960)


[Vortex-Dark-Icons](https://www.gnome-look.org/p/149343/)



>[!IMPORTANT]
> Check out the 'theme images' folder in the general section of this repo for a more detailed visual example of the i3 themes! 






