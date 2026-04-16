![Banner](https://github.com/HexdDesign/i3-Theme-Switcher/blob/34618838b0f5ac5d7917c7c821ed8e68efbbd146/theme%20images/dotsbydizzybanner.png "Dots by Dizzy")

# README ━━━


## ── ✦ . Arch i3 Theme Switcher . ✦ ──


:sparkles: Switch themes on i3 with this stunning collection of different high quality themes to choose from. :sparkles:


***



>[!WARNING]
> Keep in mind that these dotfiles are coded for these options. ── Anything can be removed or replaced, in theory. The 'optional' section is just easier. Also, I am using systemd and zsh.
>

***

### Dependencies 

| Required        | Optional           | 
| --------------- |:------------------:| 
| i3 WM           | Dunst              | 
| Pacman          | Picom              |
| Polybar         | Feh                |
| Rofi            | Nerd Fonts         | 
| Eww             | Starship           |
| GTK 3.0         | i3lock-color       |
| GTK 4.0         | Firefox            | 
| Thunar          | Calcurse           |
| Kitty           | Btop               |
| Neofetch        |                    | 
| Pulseaudio      |                    |
| Nmcli           |                    |
| Playerctl       |                    | 
| Weather API     |                    |
| Geany           |                    |


***

## EXAMPLE OF THEMES:


***

![Scroll](https://github.com/HexdDesign/i3-Theme-Switcher/blob/47b3debbaae8b17af42cd6c9d4dddb1a1e03e6b7/theme%20images/themescroll.gif)


***


>[!TIP]
>All of the files in this repo are to be loaded under your ~/.config/ !

***

## —— ⊹ i3 KEYBINDS ⊹ ——

**i3 Keybinds - They can be altered to your preferences in the config file:**

```
~/.config/i3/config 
```
   
- [Click to see i3's official site for more information about keybindings](https://i3wm.org/docs/userguide.html#_default_keybindings)

>[!NOTE]
>Keybind cheat sheet can be found within general file location in this repo as a text file by the name of - Keybind Cheat Sheet. However, here are some ones to note:

:star: Mod4: ALT 

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

***

>[!TIP]
>File location cheat sheet can also be found in the general location in this repo as a text file by the name of - File Location.

***


:seedling: 


<details> 
   
<summary>Click for some more important notes about this repo:</summary>
<br>
:warning: Do not physically add files such as: current.conf, current.env, etc. symlink files. The theme switcher script will handle it.
<br>


:star: ROFI:

• app-launcher.rasi - This .rasi file is global for the application launcher.
 
• theme-picker.rasi - This .rasi file is global for the theme switcher.

• app-themes/(name-of-theme) - This is the file to change icon theme

<br>

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

<br>

:star: EWW:

• Quickapps Included: Proton Mail, Proton VPN, Steam, Discord, Firefox, Tor, VS Code, Github, and Jellyfin. 

• Sidebar - You can add your own quickapps to sidebar. 

   ── Add them in the global yuck file:
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

(Suggestion: Use SVGRepo.com to create free SVG images for added sidebar quickapps. Colors used with other quickapps are included in a note in the 'Eww' file for an easy transition!)

<br>

:star: THEME.ENV:

• The theme.env file within each:
   ```
   ~/.config/i3/(theme)
   ```

   - control links to other files
   - control i3-lock-color colors
   - control dunst notification colors

</details>


***

### CURRENT THEMES
   - Arch-Rain
   - Blue-Yellow
   - BRS (Black Rock Shooter)
   - Celty (Durarara)
   - Chill
   - Crimson
   - Devilman (Devilman Crybaby)
   - Digital-Circus (GLITCH / Gooseworx - 'The Amazing Digital Circus')
   - Dracula
   - Ember-Moon
   - ENA (Joel G.)
   - Evangelion (Evangelion)
   - MSI-White (MSI - Micro-Star International Co., Ltd)
   - N7-Day (Mass Effect)
   - Neon-Violet
   - Nord
   - Project-Hail-Mary (Project Hail Mary 2026)
   - Purple-Plastic (Melgeek)
   - Sakura-Hunter (Monster Hunter)
     
***



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

[Ars-Light-Icons](https://www.gnome-look.org/p/2192424)



>[!IMPORTANT]
> Check out the 'theme images' folder in the general section of this repo for a more detailed visual example of the i3 themes! 






