v()
{
	espeak -w "$1.wav" "$2"
	normalize "$1.wav"
	oggenc -q1 "$1.wav" -o "$1.ogg"
	rm -f "$1.wav"
}

v player/death                 "Mine Leyben!"
v player/fall                  "Ooh!"
v player/drown                 "Gloog gloog gloog!"
v player/gasp                  "Ha!"
v player/jump                  "Hem!"
v player/pain25                "Owowowow!"
v player/pain50                "Owow!"
v player/pain75                "Ouuu!"
v player/pain100               "Ouch!"
v player/fall                  "Arh!"
v player/falling               "Aaaaaaaaaaaaaaaaaaaaa!"
v coms/attack                  "Attack!"
v coms/attackinfive            "Attack in 5! In 4! In 3! In 2! In 1! Attack NOW!"
v coms/meet                    "Let's meet at the waypoint."
v coms/seenflag                "I've seen the flag!"
v coms/taunt                   "Double facepalm!"
v coms/teamshoot               "I'm on your team!"
v coms/incoming                "Incoming!"
v coms/coverme                 "Cover me!"
v coms/needhelp                "I need help!"
v coms/defend                  "Defend the base!"
v coms/freelance               "Do whatever you want."
v coms/flagcarriertakingdamage "Our flag carrier is taking damage!"
v coms/getflag                 "Somebody get our flag back!"
v coms/affirmative             "Affirmative."
v coms/attacking               "I'm attacking."
v coms/defending               "I'm defending."
v coms/roaming                 "I'm roaming around."
v coms/onmyway                 "I'm on my way."
v coms/droppedflag             "I dropped the flag!"
v coms/negative                "Negative."
v coms/seenenemy               "I've seen an enemy."
