- blinky
  - basic hello world
- blade_blinky
  - blinks all the LEDs on the LED Blade while inserted into Slot #1
- counter
  - The Blade LEDs count in binary in Slot 1
- shifty
  - A cylon effect
- SevenSeg
  - Decimal to segment decoder and a counter for testing. Uses Tile 1.

# Pinout of Long pmod
Tile 1 used by 7seg

```
Tile                 Actual
tile2[0] = 4 top       4
tile2[1] = 4 bot       4
tile2[2] = 3 top       4
tile2[3] = 3 bot       4

tile2[4] = top 15
tile2[5] = top 14
tile2[6] = top 13
tile2[7] = top 12
Gap
tile2[8] =  top 10
tile2[9] =  top 9
tile2[10] = top 8
tile2[11] = top 7
```

```
Tile                 Actual
tile3[0] = B1 = IO_2B = TB0
tile3[1] = ?

```


# Blades
The slots are number as 1,2,3,4. The 5th slot is an SD/MMC card slot for the **STM32**.

Looking at the smaller board (aka BlackiceNxt):

From the backside (when connected together)
```
               Tile 3              Tile 1
        *-------------------------------------*
        |                                     |
        |                                     |
Blade 2 |                                     | Blade 1
        |                                     |        
        |                                     |        
Blade 3 |            BlackiceNxt              | USB-C  
        |                                     |        
        |                                     |        
Blade 4 |                                     | SD/MMC 
        |                                     |
        |                                     |
        *-------------------------------------*
               Tile 4              Tile 2
```

From the front
```
                    Tile 1              Tile 3
             *-------------------------------------*
             |                                     |
             |                                     |
   Blade 1   |                                     | Blade 2
             |                                     |
             |                                     |
   USB-C     |            BlackiceNxt              | Blade 3
             |                                     |
             |                                     |
   SD/MMC    |                                     | Blade 4
             |                                     |
   Blue LED  |                                     |
             *-------------------------------------*
                    Tile 2              Tile 4
```