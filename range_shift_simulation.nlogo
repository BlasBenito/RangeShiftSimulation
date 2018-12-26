;;LOAD GIS EXTENSION
extensions [ gis ]

;;TREE BREEDS
breed [Atrees Atree]
;breed [Btrees Btree] ;another tree species

;;DISPERSER BREEDS
breed [Adispersers Adisperser]
;breed [Bdispersers Bdisperser]


;;GLOBAL VARIABLES
globals [

  ;Time-space variables
  area ;study area defined by a map
  year ;current year of the simulation
  Atree-path-suitability ;folder with the habitat suitability maps

  ;;Atree variables
  Atree-suitable-patches         ;agentset of suitable patches for Atrees
  Atree-suitable-patches-count   ;number of patches in Atree-suitable-patches
  Atree-presence-patches         ;patches with presence
  Atree-presence-patches-count   ;number of patches with presence
  Atree-seeds-produced-count     ;number of seeds produced
  Atree-seeds-stock-count        ;number of seeds in stocks
  Atree-seeds-stock-patches      ;patches with seeds stocks
  Atree-seeds-germinated-count   ;number of seeds germinated
  Atree-seedlings-count          ;number of seedlings (<3 years)
  Atree-seedlings-deads-count    ;number of dead seedlings
  Atree-saplings-count           ;number of saplings (>3 years and <reproductive age)
  Atree-saplings-deads-count     ;number of dead saplings
  Atree-reproductive-patches     ;patches with reproductive trees
  Atree-reproductive-count       ;number of reproductive individuals (> reproductive age)
  Atree-reproductive-deads-count ;number of dead reproductive individuals
  Atree-tolerant-count           ;number of reproductive individuals outside of suitable conditions
  Atree-tolerant-deads-count     ;number of dead tolerant individuals
  Atree-initial-elevation        ;initial Landscape-elevation
  Atree-current-elevation        ;current Landscape-elevation
  Atree-elevation-shift          ;Landscape-elevation shift
  Atree-reproductive-age         ;age of transition from sapling to reproductive
  Atree-stocks                   ;patches with suitable conditions for germination
  ;Atree-max-seeds                ;maximum number of seeds produced by patch [SLIDER]

  ;germination probabilities
  Atree-gerprob-crops
  Atree-gerprob-rocks
  Atree-gerprob-holmoak
  Atree-gerprob-pyroak
  Atree-gerprob-pines
  Atree-gerprob-genista
  Atree-gerprob-grassland
  Atree-gerprob-trees
  Atree-gerprob-shrubs

  ;Adisperser variables
  Adisperser-dispersal-kernel-list ;field observations of dispersal distances
  Adisperser-target-landcover-list ;field observations of selected Landscape-landcovers
  Adisperser-elevation-change-list ;field observations of flight direction
  Adisperser-target-patch          ;patch selected on each dispersal event
] ;end of global variables

;;LANDSCAPE ATTRIBUTES
patches-own [
  Landscape-elevation                     ;elevation taken from a digital elevation model
  Landscape-landcover                     ;landcover taken from a land-use map
  Landscape-landcover-label               ;landcover labels

  ;Atree variables
  Landscape-Atree-suitability-continuous  ;habitat suitaibility
  Landscape-Atree-suitability-binary      ;binary habitat suitability
  Landscape-Atree-state                   ;life stage
  Landscape-Atree-age                     ;age of trees
  Landscape-Atree-initial-presence        ;Used just to load the presences from the GIS map
  Landscape-Atree-germination-probability ;Germination probability defined from different sources
  Landscape-Atree-random-effect           ;random number to perform binomial trials to represent environmental stochasticity
  Landscape-Atree-seed-production         ;number of acorns produced on each patch
  Landscape-Atree-stock                   ;is any stock in this patch? 1 - yes; 0 - no
] ;end of landscape attributes


;;################
;;SETUP SIMULATION
;;################

to setup

  ;clears the landscape
  clear-all

  ;starting year (define the year depending on the length of the burn-in period)
  set year 2005


  ;Adisperser SETUP
  ;----------------
  ;Dispersal kernel taken from field observations
  set Adisperser-dispersal-kernel-list [ 1 1 1 1 1 1 2 2 2 2 2 2 3 3 3 3 3 3 3 3 3 4 4 4 4 4 4 4 4 5 5 5 5 5 5 5 5 5 5 5 5 5 5 6 6 7 8 9 10 ]
  ;Preferred landcovers  to stock seeds
  set Adisperser-target-landcover-list [ 7 7 7 7 7 7 7 7 7 7 7 5 5 5 5 5 5 5 5 5 5 5 5 3 3 3 3 3 3 3 2 2 2 ]
  ;Does Adisperser flights horiz, up or down?: 1 up - 2 same - 3 down
  set Adisperser-elevation-change-list [ 1 1 2 2 2 2 2 2 2 2 2 3 3 3 3 3 3 3 3 3 3 3 ]

  set Adisperser-target-patch [0]


  ;Landscape SETUP
  ;---------------
  ;elevation
  gis:apply-raster gis:load-dataset "gis/elevation.asc" Landscape-elevation

  ;extension and resolution of the study area
  set area gis:load-dataset "gis/elevation.asc"
  gis:set-world-envelope gis:envelope-of area

  ;landcover
  gis:apply-raster gis:load-dataset "gis/landcover.asc" Landscape-landcover
  ask patches [
  ;apply categories and germination probabilities
  if Landscape-landcover = 1 [set Landscape-landcover-label "unavailable"]
  if Landscape-landcover = 2 [set Landscape-landcover-label "crops"]
  if Landscape-landcover = 3 [set Landscape-landcover-label "rocks"]
  if Landscape-landcover = 4 [set Landscape-landcover-label "holm oak"]
  if Landscape-landcover = 5 [set Landscape-landcover-label "pyrenean oak"]
  if Landscape-landcover = 6 [set Landscape-landcover-label "pines"]
  if Landscape-landcover = 7 [set Landscape-landcover-label "genista"]
  if Landscape-landcover = 8 [set Landscape-landcover-label "grassland"]
  if Landscape-landcover = 9 [set Landscape-landcover-label "trees"]
  if Landscape-landcover = 10 [set Landscape-landcover-label "shrubs"]
  ]


  ;Atree SETUP
  ;-----------
  ;reproductive age
  set Atree-reproductive-age 16

  ;probabilities of germination (DANGER, THESE ARE JUST VERY ROUGH ESTIMATES!!)
  set Atree-gerprob-crops 20
  set Atree-gerprob-rocks 30
  set Atree-gerprob-holmoak 60
  set Atree-gerprob-pyroak 60
  set Atree-gerprob-pines 60
  set Atree-gerprob-genista 50
  set Atree-gerprob-grassland 20
  set Atree-gerprob-trees 60
  set Atree-gerprob-shrubs 40

    ask patches [
  if Landscape-landcover-label = "unavailable" [set Landscape-Atree-germination-probability 0]
  if Landscape-landcover-label = "crops" [set Landscape-Atree-germination-probability (precision random-normal Atree-gerprob-crops 10 0)]
  if Landscape-landcover-label = "rocks" [set Landscape-Atree-germination-probability (precision random-normal Atree-gerprob-rocks 10 0)]
  if Landscape-landcover-label = "holm oak" [set Landscape-Atree-germination-probability (precision random-normal Atree-gerprob-holmoak 10 0)]
  if Landscape-landcover-label = "pyrenean oak" [set Landscape-Atree-germination-probability (precision random-normal Atree-gerprob-pyroak 10 0)]
  if Landscape-landcover-label = "pines" [set Landscape-Atree-germination-probability (precision random-normal Atree-gerprob-pines 10 0)]
  if Landscape-landcover-label = "genista" [set Landscape-Atree-germination-probability (precision random-normal Atree-gerprob-genista 10 0)]
  if Landscape-landcover-label = "grassland" [set Landscape-Atree-germination-probability (precision random-normal Atree-gerprob-grassland 10 0)]
  if Landscape-landcover-label = "trees" [set Landscape-Atree-germination-probability (precision random-normal Atree-gerprob-trees 10 0)]
  if Landscape-landcover-label = "shrubs" [set Landscape-Atree-germination-probability (precision random-normal Atree-gerprob-shrubs 10 0)]
    ]

  ;initializes random effect, tree age, seed production and seed stocks
  ask patches [
  ;random value to apply probability tests (germination)
  set Landscape-Atree-random-effect random 100
  ;defines tree-age zero for all the patches (age is the main state variable, 0 means "absent")
  set Landscape-Atree-age 0
  ;initialize stocks
  set Landscape-Atree-stock 0
  ]

  ;load presence map
  gis:apply-raster gis:load-dataset "gis/presencia.asc" Landscape-Atree-initial-presence

  ;set tree age randomly with a mean of 100
  define-Atree-presence-patches
  ask Atree-presence-patches [set Landscape-Atree-age (precision random-normal 50 30 0)]

  ;Atree elevation
  set Atree-initial-elevation mean [Landscape-elevation] of Atree-presence-patches
  set Atree-elevation-shift 0
  set Atree-current-elevation mean [Landscape-elevation] of Atree-presence-patches

  ;habitat suitability
  set Atree-path-suitability (word "scenarios/" scenario "/rob_" year ".asc")
  gis:apply-raster gis:load-dataset Atree-path-suitability Landscape-Atree-suitability-continuous

  ;define states and colors
  simulate-transition

  ;-----------
  ;END OF Atree SETUP

  ;creates output file
  create-output-file

  ;reset ticks of a previous simulation
  reset-ticks

  ;exports a snapshot of the initial state
  export-snapshot

end ;end of setup


;;#############
;;RUN THE MODEL
;;#############

to go

  ;; set the year name
  set year (year + 1)

  simulate-climate-change

  simulate-seed-production

  simulate-dispersal

  if Snapshots? [export-view (word "output/snapshots/"year"b.png")]

  simulate-germination

  simulate-transition

  define-Atree-presence-patches

  ;export model window
  export-snapshot

  ;computes Landscape-elevational shift
  compute-Atree-elevation-shift

  simulate-time

  reset-annual-variables

    ;plot counts
  plot-Atree-counts

  fill-output-file

  ;;stops at 90 iterarions
  if year = 2100 [stop]

  ;;count a tick
  tick

end ;end to go


;;####################################
;;FUNCTIONS TO CREATE USEFUL AGENTSETS
;;####################################

;;AGENTSET OF PATCHES WITH Atree PRESENCE
to define-Atree-presence-patches
  set Atree-presence-patches patches with
  [Landscape-Atree-initial-presence = 1
    or Landscape-Atree-state = "seedling"
    or Landscape-Atree-state = "sapling"
    or Landscape-Atree-state = "reproductive"
    or Landscape-Atree-state = "tolerance"]

  ;count presence patches
  set Atree-presence-patches-count count Atree-presence-patches
end


;;AGENTSET OF PATCHES WITH SEED STOCKS
to define-Atree-stocks
  set Atree-stocks patches with [Landscape-Atree-stock = 1]
end

;;AGENT SET WITH SEED PRODUCTORS
to define-Atree-reproductive-patches
  set Atree-reproductive-patches patches with [Landscape-Atree-state = "reproductive"]
end

;;AGENTSET OF SUITABLE HABITAT
to define-Atree-suitable-patches
  set Atree-suitable-patches patches with [Landscape-Atree-suitability-binary = "suitable"]
end



;;######################
;;RESET ANNUAL VARIABLES
;,######################
to reset-annual-variables
  ask patches [

  ;resets the number of seeds produced
  set Landscape-Atree-seed-production 0

  ;reset deads (to count only the deads of the current year)
  ;un poco cutre, mejorar!!
  if Landscape-Atree-suitability-binary = "unsuitable"
  and Landscape-Atree-state = "dead"
  [set Landscape-Atree-state "absence"
   set Landscape-Atree-age 0
    set pcolor white]

  if Landscape-Atree-suitability-binary = "suitable"
  and Landscape-Atree-state = "dead"
  [set Landscape-Atree-state "absence"
    set Landscape-Atree-age 0
    set pcolor 8]

  ]

  simulate-transition
end



;;#########################################
;;DEFINE STATE VARIABLES FOR Atree PRESENCE
;;#########################################
to simulate-transition

  ;transitions defined by Landscape-Atree-age and binary habitat suitability
  ;-------------------------------------------------------------------------
  if Atree-transition = "complexity1" [

  ;define state for suitable and non-suitable habitat
  ask patches [
    if Landscape-Atree-suitability-continuous < Atree-threshold
    and Landscape-Atree-age = 0
    [set Landscape-Atree-suitability-binary "unsuitable"
     set Landscape-Atree-state "absence"]

    if Landscape-Atree-suitability-continuous >= Atree-threshold
    and Landscape-Atree-age = 0
    [set Landscape-Atree-suitability-binary "suitable"
     set Landscape-Atree-state "absence"]

    if Landscape-Atree-suitability-continuous < Atree-threshold
    and Landscape-Atree-age > 0
    and Landscape-Atree-age <= 3
    [set Landscape-Atree-suitability-binary "unsuitable"
     set Landscape-Atree-state "dead"]

    if Landscape-Atree-suitability-continuous > Atree-threshold
    and Landscape-Atree-age > 0
    and Landscape-Atree-age <= 3
    [set Landscape-Atree-suitability-binary "suitable"
     set Landscape-Atree-state "seedling"]

    if Landscape-Atree-suitability-continuous < Atree-threshold
    and Landscape-Atree-age > 3
    and Landscape-Atree-age <= 16
    [set Landscape-Atree-suitability-binary "unsuitable"
     set Landscape-Atree-state "tolerance"]

    if Landscape-Atree-suitability-continuous > Atree-threshold
    and Landscape-Atree-age > 3
    and Landscape-Atree-age <= 16
    [set Landscape-Atree-suitability-binary "suitable"
     set Landscape-Atree-state "sapling"]

    if Landscape-Atree-suitability-continuous < Atree-threshold
    and Landscape-Atree-age > 16
    [set Landscape-Atree-suitability-binary "unsuitable"
     set Landscape-Atree-state "tolerance"]

    if Landscape-Atree-suitability-continuous > Atree-threshold
    and Landscape-Atree-age > 16
    [set Landscape-Atree-suitability-binary "suitable"
     set Landscape-Atree-state "reproductive"]


  ]
  draw-colors
  ]

end

;;###############
;;SEED PRODUCTION
;;###############
to simulate-seed-production

  ;agentset with reproductive trees
  define-Atree-reproductive-patches

  ask Atree-reproductive-patches[

  ;Null Model, seeds are produced by chance
  ;----------------------------------------
  if Atree-seed-production = "NULL MODEL"[
    set Landscape-Atree-seed-production (precision random Atree-max-seeds 0)
  ]

  ;Atree-max-seeds are produced in suitable habitat
  ;------------------------------------------------
  if Atree-seed-production = "complexity1"[
    set Landscape-Atree-seed-production Atree-max-seeds
  ]

  ;Seeds are produced proportionally to habitat suitability (only within suitable habitat), to a maximum of Atree-max-seeds
  ;--------------------------------------------------------
  if Atree-seed-production = "complexity2"[
    ;define the extremes of the ranges (local variables)
    let As Landscape-Atree-suitability-continuous
    let Bs min [Landscape-Atree-suitability-continuous] of Atree-reproductive-patches
    let Cs max [Landscape-Atree-suitability-continuous] of Atree-reproductive-patches
    let Ds 1
    let Es Atree-max-seeds
    ;interpolates the number of seeds according to habitat suitability
    ;http://habitualcode.com/post/2010/10/10/Scaling-Numbers-From-One-Number-Range-To-Another.aspx
    ;http://stackoverflow.com/questions/929103/convert-a-number-range-to-another-range-maintaining-ratio
    set Landscape-Atree-seed-production (((As - Bs) * (Es - Ds)) / (Cs - Bs)) + Ds
    set Landscape-Atree-seed-production (precision Landscape-Atree-seed-production 0)
    ]

  ]

  ;set Atree-initial-elevation mean [Landscape-elevation] of Atree-presence-patches

end

;;##############
;;CLIMATE CHANGE
;;##############
to simulate-climate-change
  ;load the habitat suitability map of the next year to perform a new iteration
  set Atree-path-suitability (word "scenarios/" scenario "/rob_" year ".asc")
  gis:apply-raster gis:load-dataset Atree-path-suitability Landscape-Atree-suitability-continuous
end


;;#########
;;MIGRATION
;;#########
to simulate-dispersal

      ;ask the agentset to generate Adispersers
      ask Atree-reproductive-patches [

      ;generate Adispersers according habitat suitability plus a random value in the interval [1, 100]
      sprout-Adispersers (precision Landscape-Atree-seed-production 0)
      [
      set color blue
      set size 5
      set shape "hawk"
      ]

      ask Adispersers[

        ;the bird mades a decision
        Adisperser-decision-making

        ;Adisperser fly
        ifelse Adisperser-target-patch = NOBODY or Adisperser-target-patch = 0
        [Adisperser-decision-making] ;selects another target
        [move-to Adisperser-target-patch if not can-move? 1 [die]]

        ;stocks the seed
        ifelse Landscape-Atree-state = "absence"
        or Landscape-Atree-state = "dead"
        [set Landscape-Atree-stock 1 set pcolor 44] [die]

        die ;all Adispersers die
        ]

      ]

end

;;###########
;;Adisperser-DECISION-MAKING
;;###########
to Adisperser-decision-making

  ;random dispersal, the dispersal kernel is uniform (NULL MODEL)
  ;------------------------------------------------------
  if Atree-dispersal = "NULL MODEL" [
      ;selects a distance from the dispersal kernel
      let Adisperser-flying-distance max Adisperser-dispersal-kernel-list

      ;agentset with patches at dispersal distance
      let Adisperser-target-patches-list
      patches in-cone Adisperser-flying-distance 360

      ;selects the target cell
      set Adisperser-target-patch one-of Adisperser-target-patches-list
    ]


  ;uses the observed dispersal kernel
  ;------------------------------------------------------
  if Atree-dispersal = "complexity1" [
      ;selects a distance from the dispersal kernel
      let Adisperser-flying-distance one-of Adisperser-dispersal-kernel-list

      ;agentset with patches at dispersal distance
      let Adisperser-target-patches-list
      patches in-cone Adisperser-flying-distance 360

      ;selects the target cell
      set Adisperser-target-patch one-of Adisperser-target-patches-list
    ]


  ;uses the observed dispersal kernel and land-use
  ;-----------------------------------------------
  if Atree-dispersal = "complexity2" [
      ;selects a distance from the dispersal kernel
      let Adisperser-flying-distance one-of Adisperser-dispersal-kernel-list

      ;selection of target landcover
      let Adisperser-target-Landscape-landcover one-of Adisperser-target-landcover-list

      ;agentset with patches at dispersal distance
      let Adisperser-target-patches-list
      patches in-cone Adisperser-flying-distance 360
      with [Landscape-landcover = Adisperser-target-Landscape-landcover]

      ;selects the target cell
      set Adisperser-target-patch one-of Adisperser-target-patches-list
    ]

  ;dispersal defined by the observed behavior of the bird
  ;------------------------------------------------------
  if Atree-dispersal = "complexity3" [

      ;selection of target landuse
      let Adisperser-target-Landscape-landcover one-of Adisperser-target-landcover-list

      ;selects a distance from the dispersal kernel
      let Adisperser-flying-distance one-of Adisperser-dispersal-kernel-list

      ;agentset with patches at dispersal distance with the target Landscape-landcover
      let Adisperser-target-patches-list
      patches in-cone Adisperser-flying-distance 360
      with [Landscape-landcover = Adisperser-target-Landscape-landcover]

      ;the Adisperser decides the Landscape-elevation change
      let Adisperser-Landscape-elevation-change one-of Adisperser-elevation-change-list

      ;defines the Adisperser's Landscape-elevation
      let Adisperser-Landscape-elevation Landscape-elevation

      ;selects the target cells 1 up; 2 same; 3 down
      if Adisperser-Landscape-elevation-change = 1
      [set Adisperser-target-patch one-of Adisperser-target-patches-list with [Landscape-elevation > Adisperser-Landscape-elevation]]

      ;not the same Landscape-elevation, but just 20 meters interval
      if Adisperser-Landscape-elevation-change = 2
      [set Adisperser-target-patch one-of Adisperser-target-patches-list with [Landscape-elevation > Adisperser-Landscape-elevation - 10
          or Landscape-elevation < Adisperser-Landscape-elevation + 10]]

      if Adisperser-Landscape-elevation-change = 3
      [set Adisperser-target-patch one-of Adisperser-target-patches-list with [Landscape-elevation < Adisperser-Landscape-elevation]]
  ]
end


;;###########
;;GERMINATION
;;###########
to simulate-germination

  ;creates the agentset with the stocks
  define-Atree-stocks
  define-Atree-suitable-patches

  ask Atree-stocks [

  ;random germination (NULL MODEL)
  ;-------------------------------
  if Atree-germination = "NULL MODEL" [
    if random 100 > Landscape-Atree-random-effect
    [set Landscape-Atree-state "seedling" set Landscape-Atree-age 1]
    ]

  ;germination defined by binary habitat suitability
  ;-------------------------------------------------
  if Atree-germination = "complexity1" [
    if Landscape-Atree-suitability-binary = "suitable"
    [set Landscape-Atree-state "seedling" set Landscape-Atree-age 1]
    ]

  ;probability of germination defined linearly by habitat suitability above the Atree-threshold
  ;---------------------------------------------------
  if Atree-germination = "complexity2" [
    if Landscape-Atree-suitability-binary = "suitable"
    ;random trial: produces a random number between Atree-threshold and 100, and compares it against habitat suitability
    and Landscape-Atree-suitability-continuous > Atree-threshold + random (100 - Atree-threshold)
    [set Landscape-Atree-state "seedling" set Landscape-Atree-age 1]
    ]

  ;probability of germination defined by landcover inside binary suitable habitat
  ;produces a continuous presence pattern
  ;---------------------------------------------------
  if Atree-germination = "complexity3" [
    if Landscape-Atree-suitability-binary = "suitable"
    and Landscape-Atree-germination-probability > random 100 ;produces a continuous presence pattern
    [set Landscape-Atree-state "seedling" set Landscape-Atree-age 1]
    ]

  ;probability of germination defined by landcover inside binary suitable habitat
  ;produces a fragmented presence pattern
  ;---------------------------------------------------
  if Atree-germination = "complexity4" [
    if Landscape-Atree-suitability-binary = "suitable"
    and Landscape-Atree-germination-probability > Landscape-Atree-random-effect
    [set Landscape-Atree-state "seedling" set Landscape-Atree-age 1]
    ]

  ;probability of germination as an interaction between habitat suitability and landcover
  ;--------------------------------------------------------------------------------------
  if Atree-germination = "complexity5" [
    if Landscape-Atree-suitability-binary = "suitable"
    and (Landscape-Atree-germination-probability + Landscape-Atree-suitability-continuous) / 2  > Landscape-Atree-random-effect
    ;and (Landscape-Atree-germination-probability + Landscape-Atree-suitability-continuous) / 2  > random 100
    [set Landscape-Atree-state "seedling" set Landscape-Atree-age 1]
    ]

  ;reinitialize stocks
  set Landscape-Atree-stock 0
  ]
end


;;###############################
;;ELEVATIONAL SHIFT
;;###############################
to compute-Atree-elevation-shift
  set Atree-current-elevation mean [Landscape-elevation] of Atree-presence-patches
  set Atree-elevation-shift Atree-current-elevation - Atree-initial-elevation
end


;;#####
;;AGING
;;#####
to simulate-time
  ;increments tree age one year
  ask Atree-presence-patches [set Landscape-Atree-age Landscape-Atree-age + 1]
end


;;OUTPUT

;;################################
;;DEFINE COLORS FOR Atree PRESENCE
;;################################
to draw-colors
   ask patches [
   if Landscape-Atree-suitability-binary = "suitable"
   and Landscape-Atree-state = "absence"
   [set pcolor 8]

   if Landscape-Atree-suitability-binary = "unsuitable"
   and Landscape-Atree-state = "absence"
   [set pcolor white]

   if Landscape-Atree-suitability-binary = "suitable"
   and Landscape-Atree-state = "seedling"
   [set pcolor 68]

   if Landscape-Atree-suitability-binary = "unsuitable"
   and Landscape-Atree-state = "dead"
   [set pcolor 18]

   if Landscape-Atree-suitability-binary = "suitable"
   and Landscape-Atree-state = "sapling"
   [set pcolor 65]

   if Landscape-Atree-suitability-binary = "unsuitable"
   and Landscape-Atree-state = "tolerance"
   [set pcolor black]

   if Landscape-Atree-suitability-binary = "suitable"
   and Landscape-Atree-state = "reproductive"
   [set pcolor 62]
   ]
end

;;###############
;;EXPORT SNAPSHOT
;;################
to export-snapshot
  if Snapshots? [export-view (word "output/snapshots/"year"a.png")]
  ;SI LA FIGURA EXISTE, ENTONCES LA EXPORTA CON UNA b EN EL NOMBRE (FALTA!!)
end


;;###########
;;PLOT COUNTS
;;###########
to plot-Atree-counts

  ;starts at year 2011 to avoid counting the burn-in period
  if year > 2011 [

  set-current-plot "Seedling-mortality"
  set Atree-seedlings-deads-count count patches with [Landscape-Atree-state = "dead"]
  set-current-plot-pen "mortality"
  plot Atree-seedlings-deads-count
  ;set Atree-seedlings-deads-count 0

  set-current-plot "Monitor"
  ;counts presence non suitable (tolerance)
  set Atree-tolerant-count count patches with [Landscape-Atree-state = "tolerance"]
  set-current-plot-pen "tolerance"
  plot Atree-tolerant-count

  ;counts presence of reproductive trees
  set Atree-reproductive-count count patches with [Landscape-Atree-state = "reproductive"]
  set-current-plot-pen "reproductive"
  plot Atree-reproductive-count

  ;counts saplings
  set Atree-saplings-count count patches with [Landscape-Atree-state = "sapling"]
  set-current-plot-pen "saplings"
  plot Atree-saplings-count

  ;counts seedlings
  set Atree-seedlings-count count patches with [Landscape-Atree-state = "seedling"]
  set-current-plot-pen "seedlings"
  plot Atree-seedlings-count
  ]
end

;;###########
;;OUTPUT FILE
;;###########

to create-output-file
  if csv?[
  if (file-exists? "output/output.csv")
  [carefully
    [file-delete "output/output.csv"]
    [print error-message]
  ]

  file-open "output/output.csv"
  file-type "year,"
  file-type "mean_elevation,"
  file-type "dead_seedling,"
  file-type "tolerant,"
  file-type "reproductive,"
  file-type "sapling,"
  file-type "seedling,"
  file-print "presence"
  file-close
  ]
end


to fill-output-file
  if csv?[
  file-open "output/output.csv"
  file-type (word year ",")
  file-type (word round Atree-elevation-shift ",")
  file-type (word Atree-seedlings-deads-count ",")
  file-type (word Atree-tolerant-count ",")
  file-type (word Atree-reproductive-count ",")
  file-type (word Atree-saplings-count ",")
  file-type (word Atree-seedlings-count ",")
  file-print (word Atree-presence-patches-count)
  file-close
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
171
15
825
640
-1
-1
2.0
1
10
1
1
1
0
1
1
1
0
322
-307
0
0
0
1
ticks
30.0

BUTTON
27
15
158
48
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
26
65
160
98
go once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

CHOOSER
25
167
160
212
scenario
scenario
"cgcm2_a2" "cgcm2_b2" "echam4_a2" "echam4_b2"
1

SLIDER
25
230
159
263
Atree-threshold
Atree-threshold
25
75
50.0
1
1
NIL
HORIZONTAL

MONITOR
845
16
895
61
year
year
17
1
11

PLOT
846
138
1259
357
Monitor
NIL
NIL
0.0
89.0
0.0
89.0
true
true
"" ""
PENS
"reproductive" 1.0 0 -14333415 true "" ""
"saplings" 1.0 0 -10899396 true "" ""
"seedlings" 1.0 0 -5509967 true "" ""
"tolerance" 1.0 0 -16777216 true "" ""

MONITOR
912
16
1030
61
Atree elev. shift
Atree-elevation-shift
0
1
11

BUTTON
27
117
159
150
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

SWITCH
24
574
165
607
Snapshots?
Snapshots?
0
1
-1000

MONITOR
844
74
976
119
Presence patches
Atree-presence-patches-count
0
1
11

CHOOSER
25
333
165
378
Atree-germination
Atree-germination
"NULL MODEL" "complexity1" "complexity2" "complexity3" "complexity4" "complexity5"
5

PLOT
850
366
1260
599
Seedling-mortality
NIL
NIL
0.0
89.0
0.0
0.0
true
false
"" ""
PENS
"mortality" 1.0 0 -1069655 true "" ""

CHOOSER
26
391
165
436
Atree-transition
Atree-transition
"complexity1"
0

CHOOSER
26
451
165
496
Atree-dispersal
Atree-dispersal
"NULL MODEL" "complexity1" "complexity2" "complexity3"
3

CHOOSER
23
511
165
556
Atree-seed-production
Atree-seed-production
"NULL MODEL" "complexity1" "complexity2"
2

SLIDER
29
286
163
319
Atree-max-seeds
Atree-max-seeds
0
100
20.0
1
1
NIL
HORIZONTAL

SWITCH
38
628
142
661
csv?
csv?
0
1
-1000

@#$#@#$#@
## WHAT IS IT?

This section could give a general understanding of what the model is trying to show or explain.

## HOW IT WORKS

This section could explain what rules the agents use to create the overall behavior of the model.

## HOW TO USE IT

This section could explain how to use the model, including a description of each of the items in the interface tab.

## THINGS TO NOTICE

This section could give some ideas of things for the user to notice while running the model.

## THINGS TO TRY

This section could give some ideas of things for the user to try to do (move sliders, switches, etc.) with the model.

## EXTENDING THE MODEL

This section could give some ideas of things to add or change in the procedures tab to make the model more complicated, detailed, accurate, etc.

## NETLOGO FEATURES

This section could point out any especially interesting or unusual features of NetLogo that the model makes use of, particularly in the Procedures tab.  It might also point out places where workarounds were needed because of missing features.

## RELATED MODELS

This section could give the names of models in the NetLogo Models Library or elsewhere which are of related interest.

## CREDITS AND REFERENCES

This section could contain a reference to the model's URL on the web if it has one, as well as any other necessary credits or references.
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

hawk
true
0
Polygon -7500403 true true 151 170 136 170 123 229 143 244 156 244 179 229 166 170
Polygon -7500403 true true 152 154 137 154 125 213 140 229 159 229 179 214 167 154
Polygon -7500403 true true 151 140 136 140 126 202 139 214 159 214 176 200 166 140
Polygon -7500403 true true 151 125 134 124 128 188 140 198 161 197 174 188 166 125
Polygon -7500403 true true 152 86 227 72 286 97 272 101 294 117 276 118 287 131 270 131 278 141 264 138 267 145 228 150 153 147
Polygon -7500403 true true 160 74 159 61 149 54 130 53 139 62 133 81 127 113 129 149 134 177 150 206 168 179 172 147 169 111
Circle -16777216 true false 144 55 7
Polygon -16777216 true false 129 53 135 58 139 54
Polygon -7500403 true true 148 86 73 72 14 97 28 101 6 117 24 118 13 131 30 131 22 141 36 138 33 145 72 150 147 147

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

sheep
false
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

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
NetLogo 6.0.2
@#$#@#$#@
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
