turtles-own [
  nearbyTurtles         ;; agentset of nearby turtles
  speed
  separationForce
  alignementForce
  cohesionForce
  flockingForce
  speedMax
  numberOfCollectedPackets
  groupTurtles
]

patches-own [
  groupPatches  ;; 0 = vide/bleu ;; 1 = rouge ;; 2 = vert
]

globals
[
  currentNumberObjects
  ticksToZeroObjects
]

to bigSetup
  setup
  setup-objects
  clear-all-plots
end

to setup
  clear-turtles
  create-turtles numberAgents
    [
      set shape "boat 3"
      set color yellow - 2 + random 7  ;; random shades look nice
      set size 4  ;; easier to see
      setxy random-xcor random-ycor
      set nearbyTurtles no-turtles
      set flockingForce [0 0]
      set speed [0 0]
      set speed replace-item 0 speed (0.2 * sin heading)
      set speed replace-item 1 speed (0.2 * cos heading)
      set speedMax 2
      set numberOfCollectedPackets 0
    ]
  reset-ticks
end

to setup-objects
  clear-patches
  set currentNumberObjects numberObjects
  set ticksToZeroObjects 0
  ask patches
  [
    set pcolor blue + random 2
  ]
  ifelse objectStrategy = "byRandom"
  [
    repeat numberObjects
    [
      let bool true
      while [bool]
      [
        ask one-of patches
        [
          if pcolor != red
          [
            set pcolor red
            set bool false
          ]
        ]
      ]
    ]
  ]
  [
    let n numberObjects / numberPackets
    let  reste numberObjects mod numberPackets
    repeat numberPackets - 1
    [
      let rayonsCroises false
      let firstTime true
      while [ rayonsCroises = true or firstTime = true]
        [
          set firstTime false
          ask one-of patches
          [
            let nearbyObjects other patches in-radius (ceiling sqrt ( n / pi ) + 1)
            set rayonsCroises false
            ask nearbyObjects
            [
              if pcolor = red
              [
                set rayonsCroises true
              ]
            ]
            if rayonsCroises = false
            [
              ask n-of n nearbyObjects
              [
                set pcolor red
              ]
            ]
          ]
        ]
    ]
    let rayonsCroises false
    let firstTime true
    while [ rayonsCroises = true or firstTime = true]
      [
        set firstTime false
        ask one-of patches
        [
          let nearbyObjects other patches in-radius (ceiling sqrt ( ( n + reste) / pi ) + 1)
          set rayonsCroises false
          ask nearbyObjects
          [
            if pcolor = red
            [
             set rayonsCroises true
            ]
          ]
          if rayonsCroises = false
          [
            ask n-of ( n + reste) nearbyObjects
            [
              set pcolor red
            ]
          ]
        ]
      ]
  ]

end

to pickUp
  if pcolor = red [
    set pcolor blue + random 2
    set numberOfCollectedPackets numberOfCollectedPackets + 1
    set currentNumberObjects currentNumberObjects - 1
  ]
end

to go
  ask turtles
  [
    pickUp
    move
  ]
  ;; the following line is used to make the turtles
  ;; animate more smoothly.
  repeat 5 [ ask turtles
    [
      fd calculateNorme speed
    ] display
  ]
  ask one-of turtles
  [
    ;;print word "separationForce= "  separationForce
    ;;print word "alignementForce= "  alignementForce
    ;;print word "cohesionForce= "  cohesionForce

    ;;print word "speed= "  speed
  ]
  ;; for greater efficiency, at the expense of smooth
  ;; animation, substitute the following line instead:
  ;;   ask turtles [ fd 1 ]
  tick
  set ticksToZeroObjects ticksToZeroObjects + 1
  if currentNumberObjects = 0 [
    stop
  ]
end

to move  ;; turtle procedure
  find-nearbyTurtles
  if any? nearbyTurtles
  [
    set separationForce calculateSeparationForce
    set alignementForce calculateAlignementForce
    set cohesionForce calculateCohesionForce

    set flockingForce
    ( map +
      (map [ [i] -> a * i ] separationForce)
      (map [ [j] -> b * j ] alignementForce)
    )
    set flockingForce
    ( map +
      flockingForce
      (map [ [k] -> c * k ] cohesionForce)
    )
    set speed (map + speed flockingForce)
    set speed (map [ [n] -> n / calculateNorme speed] speed)
    ;;Change orientation
    set heading  (acos (item 0 speed / calculateNorme speed))
  ]

end

to find-nearbyTurtles
  set nearbyTurtles other turtles in-radius vision
end

;;; Calculate separationForce
to-report calculateSeparationForce
  let separationForceTemp [0 0]
  let numberOfNearbyTurtles count nearbyTurtles
  ask nearbyTurtles
  [
    let vectorDirector [ 0 0 ]
    set vectorDirector replace-item 0 vectorDirector ( ( [ xcor ] of myself ) - xcor)
    set vectorDirector replace-item 1 vectorDirector ( ( [ ycor ] of myself ) - ycor)

    let distanceTemp calculateNorme vectorDirector
    set vectorDirector (map [ [m] -> ( 1 / distanceTemp ) * m ]  vectorDirector)

    set separationForceTemp replace-item 0 separationForceTemp ( item 0 separationForceTemp + (item 0 vectorDirector / numberOfNearbyTurtles) )
    set separationForceTemp replace-item 1 separationForceTemp ( item 1 separationForceTemp + (item 1 vectorDirector / numberOfNearbyTurtles) )

  ]
  report separationForceTemp
end


;;; Calculate alignementnForce
to-report calculateAlignementForce
  let alignementForceTemp [0 0]

  set alignementForceTemp replace-item 0 alignementForceTemp ( mean  [ item 0 speed ] of nearbyTurtles )
  set alignementForceTemp replace-item 1 alignementForceTemp ( mean  [ item 1 speed ] of nearbyTurtles )

  report alignementForceTemp
end


;;; Calculate cohesionForce
to-report calculateCohesionForce
  let gravityCenter [ 0 0 ]
  set gravityCenter replace-item 0 gravityCenter ( mean  [ xcor ] of nearbyTurtles )
  set gravityCenter replace-item 1 gravityCenter ( mean  [ ycor ] of nearbyTurtles )

  ;;show word "xcor= " xcor
  ;;show word "ycor= " ycor

  ;;print gravityCenter

  let vectorDirector [ 0 0 ]
  set vectorDirector replace-item 0 vectorDirector ( item 0 gravityCenter - xcor )
  set vectorDirector replace-item 1 vectorDirector ( item 1 gravityCenter - ycor )

  ;;print word "vectorDrector= " vectorDirector
  let sinAngle item 0 vectorDirector / calculateNorme vectorDirector
  let cosAngle item 1 vectorDirector / calculateNorme vectorDirector

  set vectorDirector replace-item 0 vectorDirector ( sinAngle )
  set vectorDirector replace-item 1 vectorDirector ( cosAngle )

  set vectorDirector map [ [l] -> speedMax * l ] vectorDirector


  let cohesionForceTemp [ 0 0 ]
  set cohesionForceTemp ( map - vectorDirector speed)

  report cohesionForceTemp
end

to-report calculateNorme [vector]
  report sqrt ((item 0 vector ^ 2) + (item 1 vector ^ 2))
end
@#$#@#$#@
GRAPHICS-WINDOW
250
10
676
437
-1
-1
5.9
1
10
1
1
1
0
1
1
1
-35
35
-35
35
1
1
1
ticks
30.0

BUTTON
39
93
116
126
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
122
93
203
126
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
9
51
232
84
numberAgents
numberAgents
1.0
1000.0
203.0
1.0
1
NIL
HORIZONTAL

SLIDER
9
183
181
216
a
a
0
1
0.0
0.1
1
Separation Weight
HORIZONTAL

SLIDER
9
216
181
249
b
b
0
1
0.0
0.1
1
Alignement Weight
HORIZONTAL

SLIDER
9
249
181
282
c
c
0
1
0.0
0.1
1
Cohesion Weight
HORIZONTAL

SLIDER
825
55
997
88
vision
vision
0
10
5.0
1
1
NIL
HORIZONTAL

SLIDER
25
330
197
363
numberObjects
numberObjects
10
100
100.0
1
1
NIL
HORIZONTAL

BUTTON
8
130
116
163
setup-objects
setup-objects
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
26
372
164
417
objectStrategy
objectStrategy
"byRandom" "byPackets"
1

SLIDER
26
430
198
463
numberPackets
numberPackets
1
10
10.0
1
1
NIL
HORIZONTAL

PLOT
792
130
1225
342
Remaining objects
Ticks
Number of objects
0.0
100.0
0.0
100.0
true
true
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot currentNumberObjects"

BUTTON
947
350
1032
383
Clear Plot
clear-all-plots
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
122
130
202
163
bigSetup
bigSetup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
850
392
907
437
Ticks
ticksToZeroObjects
17
1
11

MONITOR
1005
392
1144
437
currentNumberObjects
currentNumberObjects
17
1
11

@#$#@#$#@
## WHAT IS IT?

This model is an attempt to mimic the flocking of birds.  (The resulting motion also resembles schools of fish.)  The flocks that appear in this model are not created or led in any way by special leader birds.  Rather, each bird is following exactly the same set of rules, from which flocks emerge.

## HOW IT WORKS

The birds follow three rules: "alignment", "separation", and "cohesion".

"Alignment" means that a bird tends to turn so that it is moving in the same direction that nearby birds are moving.

"Separation" means that a bird will turn to avoid another bird which gets too close.

"Cohesion" means that a bird will move towards other nearby birds (unless another bird is too close).

When two birds are too close, the "separation" rule overrides the other two, which are deactivated until the minimum separation is achieved.

The three rules affect only the bird's heading.  Each bird always moves forward at the same constant speed.

## HOW TO USE IT

First, determine the number of birds you want in the simulation and set the POPULATION slider to that value.  Press SETUP to create the birds, and press GO to have them start flying around.

The default settings for the sliders will produce reasonably good flocking behavior.  However, you can play with them to get variations:

Three TURN-ANGLE sliders control the maximum angle a bird can turn as a result of each rule.

VISION is the distance that each bird can see 360 degrees around it.

## THINGS TO NOTICE

Central to the model is the observation that flocks form without a leader.

There are no random numbers used in this model, except to position the birds initially.  The fluid, lifelike behavior of the birds is produced entirely by deterministic rules.

Also, notice that each flock is dynamic.  A flock, once together, is not guaranteed to keep all of its members.  Why do you think this is?

After running the model for a while, all of the birds have approximately the same heading.  Why?

Sometimes a bird breaks away from its flock.  How does this happen?  You may need to slow down the model or run it step by step in order to observe this phenomenon.

## THINGS TO TRY

Play with the sliders to see if you can get tighter flocks, looser flocks, fewer flocks, more flocks, more or less splitting and joining of flocks, more or less rearranging of birds within flocks, etc.

You can turn off a rule entirely by setting that rule's angle slider to zero.  Is one rule by itself enough to produce at least some flocking?  What about two rules?  What's missing from the resulting behavior when you leave out each rule?

Will running the model for a long time produce a static flock?  Or will the birds never settle down to an unchanging formation?  Remember, there are no random numbers used in this model.

## EXTENDING THE MODEL

Currently the birds can "see" all around them.  What happens if birds can only see in front of them?  The `in-cone` primitive can be used for this.

Is there some way to get V-shaped flocks, like migrating geese?

What happens if you put walls around the edges of the world that the birds can't fly into?

Can you get the birds to fly around obstacles in the middle of the world?

What would happen if you gave the birds different velocities?  For example, you could make birds that are not near other birds fly faster to catch up to the flock.  Or, you could simulate the diminished air resistance that birds experience when flying together by making them fly faster when in a group.

Are there other interesting ways you can make the birds different from each other?  There could be random variation in the population, or you could have distinct "species" of bird.

## NETLOGO FEATURES

Notice the need for the `subtract-headings` primitive and special procedure for averaging groups of headings.  Just subtracting the numbers, or averaging the numbers, doesn't give you the results you'd expect, because of the discontinuity where headings wrap back to 0 once they reach 360.

## RELATED MODELS

* Moths
* Flocking Vee Formation
* Flocking - Alternative Visualizations

## CREDITS AND REFERENCES

This model is inspired by the Boids simulation invented by Craig Reynolds.  The algorithm we use here is roughly similar to the original Boids algorithm, but it is not the same.  The exact details of the algorithm tend not to matter very much -- as long as you have alignment, separation, and cohesion, you will usually get flocking behavior resembling that produced by Reynolds' original model.  Information on Boids is available at http://www.red3d.com/cwr/boids/.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Wilensky, U. (1998).  NetLogo Flocking model.  http://ccl.northwestern.edu/netlogo/models/Flocking.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 1998 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

This model was created as part of the project: CONNECTED MATHEMATICS: MAKING SENSE OF COMPLEX PHENOMENA THROUGH BUILDING OBJECT-BASED PARALLEL MODELS (OBPML).  The project gratefully acknowledges the support of the National Science Foundation (Applications of Advanced Technologies Program) -- grant numbers RED #9552950 and REC #9632612.

This model was converted to NetLogo as part of the projects: PARTICIPATORY SIMULATIONS: NETWORK-BASED DESIGN FOR SYSTEMS LEARNING IN CLASSROOMS and/or INTEGRATED SIMULATION AND MODELING ENVIRONMENT. The project gratefully acknowledges the support of the National Science Foundation (REPP & ROLE programs) -- grant numbers REC #9814682 and REC-0126227. Converted from StarLogoT to NetLogo, 2002.

<!-- 1998 2002 -->
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

boat 3
true
0
Polygon -1 true false 63 162 90 207 223 207 290 162
Rectangle -6459832 true false 150 32 157 162
Polygon -13345367 true false 150 34 131 49 145 47 147 48 149 49
Polygon -7500403 true true 158 37 172 45 188 59 202 79 217 109 220 130 218 147 204 156 158 156 161 142 170 123 170 102 169 88 165 62
Polygon -7500403 true true 149 66 142 78 139 96 141 111 146 139 148 147 110 147 113 131 118 106 126 71

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0
@#$#@#$#@
set population 200
setup
repeat 200 [ go ]
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
