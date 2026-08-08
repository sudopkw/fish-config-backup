# fish-config-backup

Just a back-up of my config for the fish shell
I'm aware the configuration file is ugly, Don't judge me, Please

## packages you need:
### jq (For weather, You don't need this if you only plan to use !wlegacy (Legacy weather, Provided directly by curling wttr.in))
### tor (for tor command functionality) 
### torsocks (for running vesktop trough tor ( no clue if this works, lol ))

# HOW 2 CATEGORIZE MY CUSTOM FUNCTIONZ!!!!!!!!!!!!
step 1: make function
How? read the damn fish wiki
Jokes aside:
## Make sure your function starts with ' ! ', it is the default prefix!
if you wish to change it, You very much can! 
if you decide to ignore this, Your own custom added functions will NOT show up in the !help TUI.
### After creating your desired function:
```fish
function !example --description "This is an example function in the readme."
  echo "Hello World!"
end
```
### Adding a category:
make sure that your category tag is right below the function, Else it may not work (Maybe it will, i haven't actually tested this)
Categories are added in this format:
`# category: <CategoryName>`
Here is an example of how it should look like inside of your configuration file:
```fish
function !example --description "This is an example function in the readme."
 # category: CategoryName
  echo "Hello World!"
end
```
# HOW 2 USE TOR COMMAND 4 NEWBIES!!11!1!!!
After installing tor, Run the !tor command.
You should then connect to tor.
(To Check, You can use the command !torcheck, No output = Not connected.)
(Alternatively, you can use the command !torstat for additional information)
## Install a proxy browser extension, I use FoxyProxy
1. Create a new proxy and use these settings:
 Hostname: 127.0.0.1 (local)
 port: 1337
 type: SOCKS5
2. Turn the proxy on
3. Visit a .onion site, and assuming you've done everything correctly
## Assuming everything is done correctly, You are now successfully connected to TOR!

### NOTE: I would not recommend using this to connect to .onion sites, as simply using the TOR browser is safer. However, It's good enough as a system-wide VPN alternative (assuming i actually did it correctly lol)


