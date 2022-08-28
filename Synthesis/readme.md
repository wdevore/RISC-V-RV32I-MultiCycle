- blinky
  - basic hello world
- blade_blinky
  - blinks all the LEDs on the LED Blade while inserted into Slot #1
- counter
  - The Blade LEDs count in binary in Slot 1

# Blades
The slots are number as 1,2,3,4. The 5th slot is an SD/MMC card slot for the **STM32**.

Looking at the smaller board (aka BlackiceNxt):

From the backside
```
              Tile 4              Tile 2
       *-------------------------------------*
       |                                     |
       |                                     |
Blade 4|                                     | SD/MMC
       |                                     |
       |                                     |
Blade 3|            BlackiceNxt              | USB-C
       |                                     |
       |                                     |
Blade 2|                                     | Blade 1
       |                                     |
       |                                     |
       *-------------------------------------*
              Tile 3              Tile 4
```

From the front
```
              Tile 1              Tile 3
       *-------------------------------------*
       |                                     |
       |                                     |
Blade 1|                                     | Blade 2
       |                                     |
       |                                     |
USB-C  |            BlackiceNxt              | Blade 3
       |                                     |
       |                                     |
SD/MMC |                                     | Blade 4
       |                                     |
       |                                     |
       *-------------------------------------*
              Tile 2              Tile 4
```