00
22

I have cloned an existing github repository 
and will host my copy at https://github.com/kusl/sidhant947-match3 
the original repository was at https://github.com/sidhant947/match3
I have added repository secrets 
KEYSTORE_BASE64
KEY_ALIAS
KEY_PASSWORD
STORE_PASSWORD

I copied them from an existing working repository so I think it should be right. 
that being said 

I have updated the github actions versions 
and I have added an export.sh 

there are a few things I would like to change 
1. run a full release, not a pre release, a full release with an apk with each push 
the current yaml is broken because I tried to fix it but clearly didn't fix it completely. 
please include full yaml with your response 
2. the export.sh should include all files necessary for you or any LLM 
I added  kt kts gradle properties yaml dart 
but export.sh was originally made for dotnet c sharp so I am sure I must have missed something 
3. this is the most important change and the reason why this fork exists. 
instead of showing any random hint, show the best possible move as the hint 


If only a few files (under five or there about) need to change, give me the full path of the files that need to change and the FULL file 
if there are a lot of files that need to change 
    Delivery
    Whole project as one tar.gz, unambiguous file placement
    Any files to delete on updates called out explicitly
    No bespoke sed/patch scripts — full files only for anything that changes
    Docs updated alongside code changes
    Low verbosity, no code comments
    NEVER EVER EVER write code comments. 
    in fact, never, ever write comments at all. 
    markdown files such as readme.md are the exception but even these should be as concise and terse as possible.
