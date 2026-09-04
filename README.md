## NOTE: This config is mainly for OMARCHY. ( EW OMARCHY!!!!! HOW COULD YOU USE THIZ!! BLOAT!!!!!!!!!!!!!!!!! )
> It is possible for you to use it on other systems, but you might have to get your hands dirty and rewrite some of it / remove or replace some things


## Required packages:

```
Required packages will be prompted for install once you run a command that requires them. (Mostly for modules)
```

## Installation script:

```fish
curl -fsSL https://raw.githubusercontent.com/sudopkw/pkw-fishware/main/config.fish \
  -o ~/.config/fish/config.fish
```
## Quick information:

```
> The accent color (color of the boxes, etc.) changes with your Omarchy theme
> Modules are separate, installed with the !modules command
> They will not be forcefully installed onto your system if you don't plan to use them
> The current configuration is for Omarchy Quattro!
> This configuration is still work in progress
> The screenshots of the config at the bottom of the page may be outdated
```
# HOW 2 MY CUSTOM FUNCTIONZ!!!!!!!!!!!!

```
## step 1: create a personal.fish file
This will make sure that your own commands do not get re-written once you update.
## Not creating a personal.fish file inside of ~/.config/fish/ will rewrite every custom command you add during updates.
inside the personal.fish file, follow the steps for making your own custom commands below:

```
## Make sure your custom function starts with ' ! ', it is the default prefix!

```
if you wish to change it, You very much can! 
if you decide to ignore this, Your own custom added functions will NOT show up in the !help TUI.
```
### After creating your desired function:

```fish
function !example
  echo "Hello World!"
end
```
you may want to add a description and/or a category, How do we do this? Check it out below:

### Adding a description:

Make sure the description tag is right below the function, Else it may not work (Maybe it will, i haven't actually tested this)

```
However, it's straightforward and all you need is a ' # description: <Description> ' tag.
```

- Here's an example of how it should look like inside of your configuration file:
  
```fish
function !example
 # description: This is a description!
  echo "Hello World!"
end
```

### Adding a category:

```
Adding a category is just as easy as adding descriptions, Simply add a ' # category: <CategoryName> ' tag.
```
Here is an example of how it should look like inside of your configuration file with both a description, and a category:

```fish
function !example
 # description: This is a description!
 # category: Test Category
  echo "Hello World!"
end
```
Yes, Spaces do indeed work in categories. I just personally wouldn't use them, but it's completely up to you what you do with your system.

## NOTE: When adding custom commands, you most likely won't be able to categorize them in for example SYS. 

Instead, Just add a tag like `# personal`. It will make it look cleaner, and this way you can actually have it clear of other commands and inside of the '!help' function.
In fact, I've done this too for some commands that i do not wish to update to the main config as it would reguire you guys to install a bunch of other stuff you don't need.

# HOW 2 USE TOR COMMAND 4 NEWBIES!!11!1!!!

```
After installing tor, Run the !tor command.
You should then connect to tor.
(To Check, You can use the command !torcheck, No output = Not connected.)
(Alternatively, you can use the command !torstat for additional information)
```

## Install a proxy browser extension, I use FoxyProxy

```
1. Create a new proxy and use these settings:
 Hostname: 127.0.0.1 (local)
 port: 1337
 type: SOCKS5
2. Turn the proxy on
3. Visit a .onion site, and assuming you've done everything correctly
```
## Assuming everything is done correctly, You are now successfully connected to TOR!

### NOTE: I would not recommend using this to connect to .onion sites, as simply using the TOR browser is safer. However, It's good enough as a system-wide VPN alternative (assuming i actually did it correctly lol)

# Screenies
Screenshots of the configuration file
## Info-Page
The information page displays basic information you may want such as:
Date
Location (Not fully accurate)
Current weather
VPN & TOR check (Is it running?)
<img width="417" height="271" alt="image" src="https://github.com/user-attachments/assets/a9041955-72fb-414b-b71c-4ed703d615e2" />
## !help / !commands
Displays a information box with every command in the config, along with it's description.
Including any new commands and aliases you may add (Assuming that you follow the steps above and do it correctly)
<img width="777" height="911" alt="image" src="https://github.com/user-attachments/assets/f5aefed3-2349-4236-9ac9-952d0661a35b" />
## Weather
A weather box/TUI (Not interactive) which pulls the weather for today, And the next 2 days using wttr.in!
It's pretty simple, But hey it's probably faster than going to your browser and looking up your weather. (again, Probably, you may just have hands that move at the speed of light):w
<img width="786" height="431" alt="image" src="https://github.com/user-attachments/assets/b9ca8076-3a4c-4cda-9969-381ee575f082" />



