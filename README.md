# fish-config-backup

Just a back-up of my config for the fish shell
I'm aware the configuration file is ugly, Don't judge me, Please

## packages you need:
jq (For weather, You don't need this if you only plan to use !wlegacy (Legacy weather, Provided directly by curling wttr.in))
tor (for tor command functionality) 
torsocks (for running vesktop trough tor ( no clue if this works, lol ))

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

