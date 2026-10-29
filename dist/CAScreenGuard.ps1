#Requires -Version 5.1


[CmdletBinding()]
param(
    
    [switch]$ResetPassword,
    
    [ValidateRange(5, 600)][int]$IdleBlankSeconds = 25,
    
    [switch]$SelfTest,
    
    [switch]$Ver,
    
    [ValidateSet('auto', 'zh', 'en')][string]$Lang = 'auto',
    
    
    [switch]$NoKeyboardHook
)

$ErrorActionPreference = 'Stop'



$script:AppVersion = 'V3.1.1'
if ($Ver) {
    Write-Host ('CAScreenGuard ' + $script:AppVersion)
    Write-Host '作者 / Author : @Conste11ation117'
    Write-Host '许可 / License: MIT'
    exit 0
}




$script:WordmarkB64 = @'
iVBORw0KGgoAAAANSUhEUgAAAp4AAAB0CAYAAAAsNjJeAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAA
DsMAAA7DAcdvqGQAAB10SURBVHhe7Z0tkGS5sYUNH3zQ0NDQ0PBBw4WGCxcuNFxmONBw4EDDgQMHDjRsaFjTVTWxcF5kSZq+
nVe692SmpPrp80WcCHu2pfujv6OUruoPfyCEEEIIIYQQQgghhBBCCCGEEEIIIYQQQgghhBBCCCGEEEIIIYQQQgghhBBCCCGE
EEIIIYQQQgghhBBCCCGEEEIIIYQQQgghhBBCCCGEEEIIIYQQQgghhBBCCCGEEEIIIYQQQgghhBBCCCGEEEIIIYQQQgghhBBC
CCGEEEIIIYQQQgghhBBCCCGEEEIIIYQQQgghhBBCCCGEEEIIIYQQQgghhJDeHI/HP3/9evzH8/Ppt+fn87+Px/On4/H8+Xg8
fz8eT1/S/z99TP/99Jv8vc7jmnz//v1/TqfT/1l0OJz/ovO5Nrkcfjkezx9yGYieUjlcyuOTlI+UgZTXrZUDIeSxOZ/Pf5Q+
Ko0D394v+qlD7qsu//90+vbPPFb8pPMghCSen5//qr1JTeJxdNq7RDqQ5+fTr8/P5/9kY2OSpJP0h8Pvf9J5z0Y6N31/gA46
n2sg5ZA76f9W7nFXuRxubjJACHkMZND7+vX09xyUWPVBe5K+7XQ6/0sGWZ03IW+ZRWBpU7fgs0IcDof/9XYgLUl+kq++1iyO
x/M7fU+Irhn1FMOZIwar+/Lr9FHy1dcihBAPeSXs93Vf41OaKNOAEiK8CeP59ev5b97I2p4kX8lfX3MGeTvA6p72JBFbndcM
5D3lpanVPXXQQZbC9DUJIQRFBrqX7Vb9Jas8+pqEvDUe2njKUkn/6FpL397P3I8gkdb1PWCSSK3ObzRpb+b6Xgbo88xyIIQ8
BrKsPnBivNTnuxxQCenEQxtP2V+jH2Sk5Hr6Hkbh3N9ZNHWf50TTedE1jDUh5H4J9qcePV1zmxYh1+RhjWf+Snr1IKM1axnb
u7+zaNY+z+fn88/62jPEJS1CCIJ8oDgp0ql0+qjvhZC3wEMaT9nE3XNjuFVyDIC+p95493cWzTDI+QSBq5WDLJ3peyKEkEL+
6NR1wkknvdP3RMij85DGE32oUZIPjkbuM4zs73y5x/HL0bGo7I9zVAMG+/RF3xMhhBRifVQfzQhUEHJLoB7tboxn/nJ69QDb
On2U6JjuACRymvf+yMHmlXRtjYy2ddqPNHSfpzPa+a5V0eTfPUecXOvEAULIbZM+PrUusctE+PiTHiukf0qHXn/7pzXPGUEA
Qm6JhzOexrM6n1BjIp2KcUnms86jF8gsHXkPI/d5ylK+vl5bpy/ovSRDu/9sRezUCSE1jPvPD+j2JHsfdfqd5xCTt8RDGU9L
lE2Ww61fFeYZMvTCRKiZsoIsPyOdKtqRepAosr5eQwdPp5t/ok7nVdVdVF5CyFQs53XqCCeC5VQV+RU2nZ6QRwX1UXcxdluO
7fEuhRuX8rtvHEf2d0pkNv1C0Pq/qb8bEg0Ug45OALy/aZwPeoaWtNCoNiHkbYD0jy/69l6nR0gfLmE/XCJ9tk5PyKPyUMYT
WYJOih1jgS6jjDB24P7OD/K3QKc3ZJ+nRHor16oo9vFP+q12neda/EUjQsgSiWDqfqIh14pMIR9Kr/OsSqcl5FFBVxvuwnji
hjC2xIyfERozVjUQc12eD3kfI7YDoJ169MB90IRPP9NTIr7pQwPZF3z6VQzyUvLvI977LOSju/xsy+f6NT2XbfvKaF7u9fyz
LoNbvN8aYnwW9enHM5QPIu+1Lsm7r5VNWlU6/ln/fU+QrUhJsSCFJbJ6F4PsDZHGmeNPun9Ndej4i/z3yKTh2kgbqI0ht/Bc
ZYxbtt3yzpE+Fd0qdxdtAnXR0aXX9LX7Ol8tiTjqtFGQ/Z1lIEK2HkRNeA20U49eOy+3r/Kt6BIBHkkyBud/AVHmH0rbEU4f
5T0gjTVCLhNp7JtqmZjUyWOdhbTDa0WZ8z7vX40fAh5kOVWeUed3LdKk6tt7fMvKRZf3Prou5cnvqu5o6XRC3oYjA+luO5Ey
lEnjiEFWBkp9vZqik2MB3RLkqX/6nbek01nR+bWk0/UkjbvyE9j7Y+BSUtckCCN94MhjDoW8FW/1XrRaHkTGNCRglHT6ImP8
6Pa+JBlNeZe7/ZJ8jPdb697ye9BpVroL44l0Zj0eBtlnWdSzoiPXlQpRronsRx2xHQCNCPcwJyUStKWWmYqSIlE2s9mSlJvk
Fa2bLfCBVh8Tc/4L3hG+lhiHVgfbm7SkCX/QtqUnMTutDnMk6UiePvVJJluj3j06aCzTWAxnRQcZYHv2peiHP9HJsYAaJc93
BzqPlnQ6Kzq/lnS6HuQTUqA9gYAOUvYjJjMCHnQ5/7xMV8YS/XeIpE31GEu3SIEHrB4rXQyobrtoHzJqPOyKvumWdDoP2ty0
pF94BHBp+cesEzGqUjF63qNg2NfU/eOrWeSygCIZFokBlUFWXy+Kx3iKcQFmtruSa7++m37kOm4+Z3dP0plrEz6SPGB1r08S
IerdvtFBY5nGO6gqfeo1IUAnKT3Mu0ze9LhQk8cM6fttSaezovNrSaeLkCKcLrOD6KDNXw88xtPyoeyOPvRu6wI6dmzr9HF5
b2ifTeN5AyD7O7WZQ2aKvQdYyU9fo6GhSzMjSEZHlntWz9Jbn3s2OrTzKHUhfyDWozO8qMeSpSb/NK4nggZLop8jOvPCjPok
kWd5V/raXqzGE9nyg0vO/I2bT/QZeveNvdH325JOZ0Xn15JO5wU1cFHJak7P9o3edzGeeeK8O0bjem3woqDjBqaXe0P7vJ5j
4DD0Tbek090L2Ozv9fFESAH3jkgZ9l6u7veW6d9J7OqpV8NDOxAZaHP5dX/OnhEGQ1S9hz737MwL8+tTn7aGmjb52zHlFPvg
R0CfgcYzofNrSafzgJq3Xuq53Qy997LfFP0uxaJek3x0y5xRl+8tEF8i6jX+DUXfdEs63T0ALpt/18s14C8IdY88ogOqRGN6
RDBmgA5WfdUnwmMxnp2WRVeSZfseHUmOdIa3AFjUqzNfcoX6dOjx/tH7lr81fuQFK7r3En0GGs+Ezq8lnc7KmInKvnq1b4vx
RP/Wo2i9lS/qR/WxaTWNxvMuAPd3Pul0yJmayw+SeoFWrKynUR8A9QLc5jBEPWbkqPHM+zqHLV9Hn2V+lPBFPTfw59/0Xl1j
tMQIRts6atrQ0z88iv7MJPoM0QF8NPp+W9LprOj8WtLpLOQTKYb1PXvqMQahZjL/HVQHfYod5TgiElskYwDa/9F4XhnM+NR/
YQOZufTuYEGj/EPpHr+979H4e3OtWfhrxZZJUeOJdghezTIMLzp9kWcq54ym/cfl7D/oWJAfShHbeP1ETptQ15XB+EM6K+/8
t/IcsncyfQVvjSrW+wkUvAxMk0+P3B8nos/Qu1/sjb7flnQ6Kzq/lnQ6C+gHJ0vluv8pH0snfZyUK1S2a8XMmoAaz777nuvy
fhg3csJYhJ6UQuN5ZZD9na3lJ6Qh9t7nKSD3XNcl3TsxCD2WmaM4n+OzNjzpf8u/WY1CPFKFGk8dTSwTgorp+SXnaY4+euua
sUOEvlqVJSXj7D58JqytPslkbL8NyEBmMdEzzL++n2yg39UmAcYy+JGft02gz0DjmdD5taTToUgd1/WlpZc+afuDuVS/sHIu
ipY3ajxrY0CeCP8mbeJlzEgHtPvah291yTMBKMa//KhFGiNOf19MBipp9kXjeUXQ/Z2taAxoOrrv8+y3Ofl6RhTZqqDvda9D
FFJE2GJA/DNYAawDSnJ/278gIwO/PUrqiywYImifrcYKfT/RiC1an+Q61vLOJhqaCHjNv+AcSN7ttd08aJtOUrC+owL6DFEj
Mhp9vy3pdFZ0fi3pdCiWsQKZUC4Bv3O4KPord6jxXCqdw7lfj/M7gtuHZwud/D06AcjX+C9y/qynbYtoPK8IsmwtlUWnK6Dp
rZUUAT0vzyYxd5eZ4aYp6oHlQxtPp4VtoSjyL5Gixmoh05lwObqg82jKkreARkQiy+FoVKG1soBgKG/XMjLS1kUyYOi0KKhp
exG+TcS6z89roNFnoPFM6Pxa0ulQ0Cibt+2h45BEInVaCw7jaTqbVowY0g8WWftCSz8u7dRy79K20YlxEY3nFQEHq2bEEo2Y
juhkrQOJXZeoHDywWbDN/k5frGZKyEdqQIOgzBh1ehSL8fRG9dDBI11jPyq8xBARcRk2AY9G+ganXNa7s37v+y+gBhqJstQw
1FfXcp9tT7XvaCX0GUb0iT3R99uSTmdF59eSToeCrP5EgiN5NWCVZ03eawhW42k1hoJlf6jVqFvGCSTSqUEnxkU0nlcEaZR7
0TYkD2/0YA/LEqBf2BK3Bcuewsi180xwlWdN3oZo6VC89SBPMiCjbl8u29+MHjVsAnIdkWWmX0CjCdFfrkLrrbecUdMWKQ/0
GrWTPBDQ/LeM58tHan3kMSH6flvS6azo/FrS6VByRFLKZEvuSaWA9k3ePlawGE/PpExIAZH1HtGarMdEof3fVqBrDzT6LIqU
xTT0Tbek090yaLRyL+oH7o9zV6Y98nNAnX1E1hneFnjkxbdncQkyMRBtDYRbyMCm82opMuNHo21yPzrtFtj7iZcDuh/MYxLQ
+uSNRC7Redbl27qBtmPvwCqgA7h3ywD6DFvtDexTYVknY4LOoyWdzorOryWd7pbA+pDtMt8DrbeiSLAC3wJma+PoO4pMji2n
etB4Xgk0NL0XgUEaRGQpAyEtNfbtrOuyNbYW+JJG/HrgdgrX4CQYjKcrglRAl9vtxhNZovYbnQLa3vYmejXQ+tSjswUjIq6J
JmraIhEqNGor0mkR0GfYMiG9+zJP29Z5tKTTWdH5taTT3RI9ynwPZJwt2huzt0AnyNY2jq9M2vu/gmXbQ4++cDj6plvS6W4Z
0JDsmgW0sCONDkUazdh9n6K4GURnlT2irLIkWY6h2JK3IeLG07dnroBfBy8fPOrvNzoFtJ14DpNH2vLWR4IWkOUs715VdAD3
vKOCZfuJTouAPsNWf0jjuZZOd0v0KPM9UOPpjdQX8Amy2XjuTvCTYh/2rvOryzveTUXfdEs63S2Dhb6xQRypVNZIVIS09Lg/
QHq1t+91D/TeeiyNjgY1hNY9QRq040XrrIB+9BMxOoX8AdAqby1PO0H2T3nNoAYxRV6Tiw7g0Xah82tJp0NAn2HLhCDv2CIa
z7H0KPM98P7v/FmntSD3WMmzJqvx1Omriq6MopFVGs8rgEZ60IgbMvBZK2oPZPaUo4u7xtiqyD6aGR3VLFDj6TFUS/COFzee
aCfrGbhr6Hxr8rwnsD51aX+oKdLpEMDnCLcLnV9LOh1Cj2dA3zEqT/3VebSk01nR+bWk0/VETEg5lFyUxwwpR1TQ+LJV5nvg
/V/shyjQPtHan1TSV6XTWaHxvGHQcDr6oQOyx2z0Ps895FnSUrzt5wxbivziT4/B6VZ4I8Yz/3xeWKu8tTzvCcxbBkd9P2ah
W1n0PSLka6zy0oq2C51fSzodQo9noPFcS6eLktu+7BuHTGMPbZX5HiP6vxponyj1XKfdopK+Kp3OCo3nDdN7TxhaWaNLZD2R
iGUyzJef5HIZUe8SbI/B6VZ4C8ZzpjzvCa1PM6XvEQF9jmi70Pm1pNMh9HgGGs+1dDovMgaBH8h111aZ7zGi/6th6BNpPEej
b7olne5WwfZ34hXLcCB6+CONEeRfr5Gv+aBK+yLfMTs9BqdbYZbxHIGhk50mz3tC69NM6XtEQJ8j2i50fi3pdAg9noHGcy2d
zoqMUehHnaO0VeZ7zDKeo1jfZ106nRV0DKfxnAy6v9P6AQ1mZn1GbSbWTh/djrCkx+B0K9B49pXnPaH1aab0PSKgzxFtFzq/
lnQ6hB7PkPamr0+e0ML6XBrPNOZh72qktsp8DxpPDBrPGwXd3zlKkTPGZmExnyONQqSjmgWNZ1953hNan2ZK3yMC+hzRdqHz
a0mnQ5j1DAJ6rbdsPI0/HTxUkTKn8cSg8bxRkP2dY+U/IHYWeesA9BGF53BxtCOMdFSzoPHsK897QuvTTOl7RECfI9oudH4t
6XQIs55BQK/1lo2nJYiwlPGDQugDpUiZ03hi0HjeKNfaWL3QTe7z1Bh+weGg0+6BDhiRjmoWb8F4GgehkJwmQdKu7lupy1ft
qPQ9IuS0+r5XirYLnV9LOh3CrGcQ0Gs569Qqn5p0Ois6v5Z0OgT0nN4XfXvvOSYPLYdImdN4YtB43iDysvU9z9ft7/MUDB9M
mbcPzOioZvFGjKd54J4JWJ9cZnAm4HOE24XOryWdDmHWMwjotTz1V+fRkk5nRefXkk6HYHg///EYzgJ6nUiZ03hi0HjeIHjl
HSurUbsW6IZ0ayWe0VHNgsbz+oD1icYzo/NrSadDmPUMAnotT/3VebSk01nR+bWk0+1hCbJETKeAlkOkzPGxm8ZT51mTdcy+
CvqmW9LpPEjlROQ5vNy736W/7Ps80S89e5rafMBw5f5fy9pxzeioZkHjeX3A+hT6Kb0ZgM8Rbhc6v5Z0OoSZP4eLvi9P/dV5
tKTTWdH5taTT7YH8qElWeOsXWg6RekvjifFQxhP90OR8Pv9Rp7WAHnUk8hlPrFAmyNzY5XinSj4V2U1tC/CnQM1HKqGG1ntA
/Uzu2XiiUREZxHTaWwKcUJr3Is9mxgAu6Pxa0ukQ0LMi0Z8j3kImEzrfmuTnIHXaPdAPZiIDONr+PHX3FicAkXr7Voxn1EPN
qLfTQJdco5VYImc6z4bMDdHQyCfIvs9TTNg6n7Ws549ugX6IZY2y4ibabtA16EdS3oHwno2noO+zrtvszAtoGUQ79dHMGMAF
nV9LOh0CWhY92jY6yHreFxqkiIx5klbn19CTTrsHasp7tAn0Wp5yKNy78USDd9bVwyWWwN1dGE808uUdvAsyM9V51mU3bnjF
jXWIqEm3mjW8kzp91Gk95PPfKvm/luWnRQuoie7xLGjd9UaK0YH2ho0nMsDe9DI1Wp8iA98MHsN4ov1srG2PHmTRsoisyqD1
1rM/GWzXrjLWoB+hRuotXq9u03ii5RGpT4bAnatNTAddPpElVJ3WArhk5uq08Lx9BqSAnxNqu47s8VznUdWhzywWO2hfoqI6
7R64iT4fPFsqlqBREet2gcIDGM/dAVZm6zrdLYHWp0inPgOkLESRAVzQ+bWk0yGg+4ajbdtwHddzoBNWzznGhZHXQI2OjCs6
rQXLkU2RevsAxhNs2/4VS3R1T3QXxtOwUdm99GBx62KEdfo90IZojURqUMNmjayiEcgs8wx5iRhXdGnANwmATXSwIaKdlb/c
H8B4QhOl+GrG8R/yDvbkMSNofZI67cm/IH2Uvt+avAMsPjj58i/o/FrS6RDQshB523bqC7GVJe+kyTaI2yetFuPsaXvoNinP
/tclUt91ni1F6i3el9+q8cQCXxI99gSObGP2nRhP4/7IJ2vnbulIRNYKjN6/J3qnQa/l3C4AzZBF0iHo9CjoxnSRN4qElrc0
RE/Hnk0CtAQUWUpGO95IeYzEMOFzR9LRa0TaH7rPLFIOaJ21rmYUHsF4Cuh78rZtSyDEOsEvWCJ5nr4cfUcizztC61Kk70NX
Gooi9fbejSd+/xeZV47RAELRXRhPwWJGpDKjjSXPkNFG4mrkeKH3qbSjoquWWXLWB4tZSGWBl3MkgmSJKKT3iQ/m+T1BZSCK
fLV978ZTQAdBmfhY62zeiweZQm8ETEDbuJgdzwZ+tL5K/t42gfaDkQFc0Pm1pNOhoO8q6wldJZP3miPn6IQytJSMbtNJOn1E
2ob0x9Y+VueBgEbY8jXMfVMetw3vJ1Zv0fbdawzvDR6QSrKMScaJ2EV3ZDzhJeSl3kllq3XE8u95acrQifiWHdBG6DnvrQYe
mcTNVAE1CUXyfmVA3xpsc0TKNGMSRYyCdNLWspcOWwapWn0ScpQCGryXijTCRzCeFqMgAyG6PCdlZVv+wSarNaROWOqTbNfB
jQLWf4g8+/EKaN2NDOCCzq8lnQ7F27Zbz5UmL8ef0OXjZZ46LwuWdiEqbaM22Zd/yx8TmcyaZ7wT8A910xgh/X/tvjWpPdjH
ClGrfBHu3XgK1rFbJuxb43Y2/9CkXisy5k0ld+zwIFLR5beSI3l4owl49Ms/O16Cd1j2RmL4ErKlH79ZHS0LpKPawjKgV7T8
7W2wfNfy7Bde8gjG02kUvsi7K3sai6R+5n831a2IYSs4BsSDXFeeQQbql2e4GGYpV8gILhUxz+j1IgO4oPNrSaezEGnbue6U
PspYL5eyT+yXRMa8fN+hZ4isKFm++l9c73dpuxJBW7bpZPqlnV/a9epZ0AlBpN4+gvHEfUFVn1JA69Kumv0EWl/vxngKzqhn
N6GRliWGELf5bNAWhv1B5vPZ8kdGzYo3S96Z+JI8e3abxqikkUbN8yMYTwHv2McoYtgKebC9Wn3y7M1agrbryAAu6Pxa0uks
WD92GKBQWRSCZiGkaB/rmIiZVVbU9L/XFKm3eP90u8YzMpFBlCYA2ITvroyngA60veVd1kUrbI+IS8Gy7OepAClChc0yRyga
JVwihgN9V73lmcho0PZw68ZTmDFQ1RQdYJdcqz5Je0SW7rd4JOMpGD/w66jTF2+ksIZlT2Yv9RiPsvkf/f4/oH1gpN6i4/gt
G0+hw4plU2mS9KDGU8D3MPaSf68OWhCWzbwI6CDi3VeaI7mm/UKd9Klnpy5Y9iP1Ui+zg3a692A8czTdtWfIr/4DBT5IddOh
R0eO9hmRAVzQ+bWk03kYOdDWJBGlHmWxZP5Ev59xRvsnr6TvRq8Rqbd4m+7fn/RmxESmbMtA/U7vNjKFtKTV/+XVhX0t2AJd
eos0ihro8kOkoeTozrDQ/VqxsthCjOCE2flFPU0g2un2vOZI8oRmlvl0HXWDMGuJNEU6+3Tij2g8BbSNRJVMZ3zLRg3Z/z/H
fJ6+9KpPhXGBojR2oeUbqbePZDx7bzGTcbOcDPHQxrMgs9lRZiG9TN8ZkQV0f6dcq9cMs2DYD2ve57lEjCBuct2SjzBckVkL
ka/0EKWvTrGjW1DQTvdejGfBc0SHQYce2xz2SEu948yC53ipLR7VeAqjy0IG3J5lUSNHPgeZuIs+9B6HhLT1q/d9vxg8tA+M
1NtHMp5C8ibmr9yrWo5pb8J4CoPMwuceX5jjldV/iG4Ly1eFPSrBuI799DH6AY4F6SRHGGn0+BwraKd7b8ZTGFGnpBxm16fe
e1flnfSewAiPbDyF1Lbhn19GdYh+vW4lr850W2lKE+JYkAUB7asAvVqpQPON1Ft8LL8P4ylEV44lYKYDQm/GeBZkkPIco7LQ
IaVvn1tlBS0E3ZB6gYbTdeWJkI7ACJWD6CmZv7j59/Jy7l1oVniQ5xhpdNBO9x6NZ6G0be+e4lwX3917fZKo0chI7aMbz4IM
eukgeP+kppTFiAghglw371+F+via5Pl79v0IKdIGj4tLSduvnvWJ9oGRevuIxrOQV0fhepRXmatlgZbtwxjPJfIic9Qqn2O2
6mDkJV/+m/zdqM5c9vskI7atWgH2AL3+qEogeUunkJdZLu9bV8Acrf4kMy/521F7pCKUgUqWojaeQ3Q56ywNav0mMFvIveny
rGlUGc/m5WOCy0xdymHVYYrRnF0OFkp9ymZ6sz5JB986FLw3eH8Ri9zr/FrS6UaQ9k6+6qNerZ7lQTaX0bf3YvZmlIUFqU/J
GKUzFivjXTnr8lM6J3NOfdoitQE5uza1gcqWuTx2X37k5detOof3ge089pD3pfOr6ZqT2yip/f/wTct+tZxZ/UH6ra26I8+v
30lN15qwEUIIIYQQQgghhBBCCCGEEEIIIYQQQgghhBBCCCGEEEIIIYQQQgghhBBCCCGEEEIIIYQQQgghhBBCCCGEEEIIIYQQ
QgghhBBCCCGEEEIIIYQQQgghhBBCCCGEEEIIIYQQQgghhBBCCCGEEEIIIYQQQgghhBBCCCGEEEIIIYQQQgghhBBCCCGEEEII
IYQQQgghhBBCCCGEEEIIIYQQQgghhBBCCCGEEEIIIYQQQgghhBBCCCGEEEIIIYQQQgghhBBCCCGEEEIIIYSQN8v/AxlBy3L8
Eh88AAAAAElFTkSuQmCC
'@
$script:WordmarkB64 = $script:WordmarkB64 -replace '\s', ''

$script:WordmarkImg = $null
$script:PowerInfo = $null
$script:LastPowerRead = [datetime]::MinValue




$script:LangArg = [string]$Lang
$script:Lang = 'zh'
try {
    $ui = [System.Globalization.CultureInfo]::CurrentUICulture.Name
    if ($ui -notlike 'zh*') { $script:Lang = 'en' }
} catch { }
$script:T = @{
    zh = @{
        k01 = "CAScreenGuard 缺少必需的文件：`n`n"
        k02 = "`n`n脚本、两个 .cs 和图标必须放在同一个目录里。请重新运行安装程序。"
        k03 = 'CAScreenGuard ' + $script:AppVersion + ' · 文件不完整'
        k04 = 'CAScreenGuard ' + $script:AppVersion + ' · 发生错误'
        k05 = '无法保存密码配置。'
        k06 = "密码错误次数较多，请等待 {0} 秒后再试"
        k08 = "密码不正确，请等待 {0} 秒后重试"
        k09 = '密码不正确，请重新输入'
        k10 = '本机没有可用的授权码，无法修改解锁密码。请重新运行安装程序。'
        k11 = '（未设置提示）'
        k12 = 'CAScreenGuard ' + $script:AppVersion + ' · 修改解锁密码'
        k13 = '修改解锁密码'
        k14 = "为确认是你本人，需要先输入授权码。（区分大小写）`n授权码提示：{0}"
        k15 = '授权码'
        k16 = '新解锁密码（至少 4 位，只用英文/数字/符号）'
        k17 = '确认新密码'
        k18 = '保存'
        k19 = '取消'
        k21 = '新密码至少需要 4 个字符。'
        k22 = '新密码只能用英文、数字和符号，不能用空格和中文。'
        k23 = '两次输入的新密码不一致，请重新输入。'
        k24 = '保存失败：'
        k25 = '解锁密码已更新：请用新密码解锁'
        k26 = '授权码连续错误 3 次，已取消修改'
        k27 = '本机没有可用的授权码，无法修改解锁密码'
        k28 = '（没有留下提示）'
        k29 = 'CAScreenGuard ' + $script:AppVersion + ' · 配置需要重建'
        k30 = '保存解锁密码的文件不见了，或者被动过'
        k31 = "这多半不是意外：文件要么被删除、要么被改写，原来的解锁密码已经作废。`n"
        k32 = "在确认是你本人之前，CAScreenGuard 不会重新开始 —— 免得有人趁这个机会换掉解锁密码。`n"
        k33 = "请用授权码确认身份，然后设一个新的解锁密码。`n"
        k34 = "授权码提示：{0}（区分大小写）"
        k35 = '授权码'
        k36 = '新解锁密码（至少 4 位，只用英文/数字/符号）'
        k37 = '确认新解锁密码'
        k38 = '确认并继续'
        k39 = '退出'
        k42 = '新密码至少需要 4 个字符。'
        k43 = '新密码只能用英文、数字和符号，不能用空格和中文。'
        k44 = '两次输入的新密码不一致，请重新输入。'
        k45 = '保存失败：'
        k46 = 'CAScreenGuard 已经在运行中，无需重复启动。'
        k47 = "本机还没有装过 CAScreenGuard。`n`n请先运行安装程序（CAScreenGuard-Setup.exe）：解锁密码和授权码都在安装向导里设置，装好后用桌面上的快捷方式启动。"
        k48 = "本机缺少 CAScreenGuard 的凭证，没法核实这份配置是谁写的。`n`n为了不让人趁这个机会换掉解锁密码，这次不会启动屏锁。`n请重新运行安装程序（先卸载，再安装）。"
        k49 = 'CAScreenGuard ' + $script:AppVersion + ' · 配置无法核实'
        k50 = '你取消了重建，所以这次不会启动屏锁。'
        k51 = '授权码连续输错 3 次，所以这次不会启动屏锁。'
        k52 = "解锁密码没有重建成功。`n`n"
        k53 = 'CAScreenGuard ' + $script:AppVersion + ' · 配置需要重建'
        k54 = '息屏保护中'
        k55 = '输入解锁密码，按 Enter 恢复屏幕'
        k56 = 'Enter 解锁　·　Ctrl+Backspace 清空　·　Esc 立即息屏　·　Ctrl+Shift+Alt+E 修改密码'
        k57 = '屏幕熄灭时，系统与后台任务仍在运行，请注意电量管理。'
        k58 = 'CAScreenGuard ' + $script:AppVersion + ' · 发生错误'
        k59 = "如果您确信没有记错授权码，则应该考虑这是否是一次有预谋的攻击。"
        k75 = "您先前收到过配置被动过的通知，且授权码连续输错：请立刻修改电脑密码、运行最新的杀毒软件，并检查您物理工作环境的安全性。重新安装本软件可以解决当前状态。"
        k60 = "CAScreenGuard " + $script:AppVersion + " · 上次没有正常结束"
        k61 = "上次息屏锁没有正常退出，但留下了崩溃日志：`n{0}`n`n这是软件自己出错退出的，不是被人关机。请把这份日志和复现步骤一起反馈。`n`n顺便检查一下电源设置：睡眠 / 休眠 / 合盖 如果设得太激进，也会在锁屏期间把它打断。"
        k62 = "上次息屏锁没有正常退出，也没有留下崩溃日志。`n`n也就是说它不是自己崩的：可能是有人按了电源键、用 Ctrl+Alt+Del 注销或关机，或者直接结束了进程。`n`n如果你刚刚回到工位、并没有重启电脑就看到这条消息，请立刻修改电脑密码、运行最新的杀毒软件、检查你物理工作环境的安全性，然后重新安装本软件。`n`n也请顺便检查电源设置：睡眠 / 休眠 / 合盖 如果设得太激进，也会在锁屏期间把它打断。"
        k63 = "已禁止输入密码"
        k64 = "请使用物理按键关机，或使用 Ctrl+Alt+Del 呼出安全界面关机"
        k65 = "已禁止输入授权码"
        k66 = "CAScreenGuard " + $script:AppVersion
        k67 = "这条封禁已经写进本机记录：关闭或重新打开本程序都不会解除，只有重新安装才能恢复。"
    }
    en = @{
        k01 = "CAScreenGuard is missing required files:`n`n"
        k02 = "`n`nThe script, both .cs files and the icon must live in the same folder. Please run the installer again."
        k03 = "CAScreenGuard " + $script:AppVersion + " · Incomplete files"
        k04 = "CAScreenGuard " + $script:AppVersion + " · Error"
        k05 = "Could not save the password configuration."
        k06 = "Too many wrong passwords. Please wait {0} seconds and try again."
        k08 = "Wrong password. Please wait {0} seconds and try again."
        k09 = "Wrong password, please try again"
        k10 = "No usable authorization code on this machine, so the unlock password cannot be changed. Please run the installer again."
        k11 = "(no hint set)"
        k12 = "CAScreenGuard " + $script:AppVersion + " · Change unlock password"
        k13 = "Change unlock password"
        k14 = "To confirm it is really you, enter the authorization code first. (case-sensitive)`nAuthorization hint: {0}"
        k15 = "Authorization code"
        k16 = "New unlock password (at least 4 chars, ASCII only)"
        k17 = "Confirm new password"
        k18 = "Save"
        k19 = "Cancel"
        k21 = "The new password needs at least 4 characters."
        k22 = "The new password may only use ASCII letters, digits and symbols — no spaces, no non-ASCII."
        k23 = "The two new passwords do not match, please retype."
        k24 = "Saving failed: "
        k25 = "Unlock password updated: use the new one to unlock"
        k26 = "Wrong authorization code 3 times, change cancelled"
        k27 = "No usable authorization code, the unlock password cannot be changed"
        k28 = "(no hint was saved)"
        k29 = "CAScreenGuard " + $script:AppVersion + " · Configuration needs to be rebuilt"
        k30 = "Unlock password file is gone or modified"
        k31 = "This is most likely not an accident: the file was either deleted or rewritten, so the old unlock password no longer counts.`n"
        k32 = "CAScreenGuard will not start over until it knows it is you — otherwise someone could swap the unlock password right here.`n"
        k33 = "Confirm with the authorization code, then set a new unlock password.`n"
        k34 = "Authorization hint: {0} (case-sensitive)"
        k35 = "Authorization code"
        k36 = "New unlock password (at least 4 chars, ASCII only)"
        k37 = "Confirm the new unlock password"
        k38 = "Continue"
        k39 = "Quit"
        k42 = "The new password needs at least 4 characters."
        k43 = "The new password may only use ASCII letters, digits and symbols — no spaces, no non-ASCII."
        k44 = "The two new passwords do not match, please retype."
        k45 = "Saving failed: "
        k46 = "CAScreenGuard is already running, no need to start it twice."
        k47 = "CAScreenGuard has not been installed on this machine yet.`n`nPlease run the installer first (CAScreenGuard-Setup.exe): the unlock password and the authorization code are set in the setup wizard, then start it from the desktop shortcut."
        k48 = "This machine is missing CAScreenGuard credentials, so this configuration cannot be trusted.`n`nTo keep someone from swapping the unlock password right now, the screen lock will not start.`nPlease run the installer again (uninstall first, then install)."
        k49 = "CAScreenGuard " + $script:AppVersion + " · Configuration cannot be verified"
        k50 = "You cancelled the rebuild, so the screen lock will not start."
        k51 = "3 wrong authorization codes, so the screen lock will not start."
        k52 = "The unlock password was not rebuilt.`n`n"
        k53 = "CAScreenGuard " + $script:AppVersion + " · Configuration needs to be rebuilt"
        k54 = "Screen protected"
        k55 = "Type your unlock password and press Enter to restore the screen"
        k56 = "Enter unlock · Ctrl+Backspace clear · Esc blank now · Ctrl+Shift+Alt+E change password"
        k57 = "The screen is off, but the system and background tasks keep running — mind your battery."
        k58 = "CAScreenGuard " + $script:AppVersion + " · Error"
        k59 = "If you are sure you did not mistype the authorization code, consider whether this is a deliberate attack."
        k75 = "You were already told that the configuration file had been tampered with, and the authorization code was then mistyped three times: change your Windows password now, run a fully updated antivirus scan and check the physical safety of your workspace. Reinstalling this software will resolve the current state."
        k60 = "CAScreenGuard " + $script:AppVersion + " · The last session did not end cleanly"
        k61 = "The last lock session did not exit cleanly, but it left a crash log:`n{0}`n`nSo the software itself failed — this was not someone shutting the machine down. Please report that log together with the steps that led to it.`n`nWhile you are here, check your power settings: aggressive sleep / hibernate / lid-close actions can also interrupt the lock."
        k62 = "The last lock session did not exit cleanly, and it left no crash log.`n`nSo it did not crash by itself: someone may have pressed the power button, signed out or shut down via Ctrl+Alt+Del, or simply killed the process.`n`nIf you have just come back to your desk and did NOT restart the computer before seeing this, change your Windows password now, run a fully updated antivirus scan, check the physical safety of your workspace, and then reinstall this software.`n`nAlso check your power settings: aggressive sleep / hibernate / lid-close actions can interrupt the lock too."
        k63 = "Password entry is disabled"
        k64 = "Power off using the physical power button, or press Ctrl+Alt+Del and shut down from the security screen"
        k65 = "Authorization code entry is disabled"
        k66 = "CAScreenGuard " + $script:AppVersion
        k67 = "This block has been recorded on this machine: closing or reopening the program will not lift it — only reinstalling can."
    }
}
function T {
    param([string]$Key)
    $t = $script:T[$script:Lang]
    if ($t -and $t.ContainsKey($Key)) { return $t[$Key] }
    return $script:T['zh'][$Key]
}



$script:ScriptDir = $PSScriptRoot
if (-not $script:ScriptDir) {
    try { $script:ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path } catch { }
}
$csEarly = Join-Path $script:ScriptDir 'ScreenLockEarly.cs'
$csNative = Join-Path $script:ScriptDir 'ScreenLockNative.cs'
$missingFiles = @()
foreach ($f in @($csEarly, $csNative)) {
    if (-not (Test-Path -LiteralPath $f)) { $missingFiles += (Split-Path -Leaf $f) }
}
if ($missingFiles.Count -gt 0) {
    $missMsg = (T 'k01') + ($missingFiles -join "`n") +
    (T 'k02')
    try {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show($missMsg, (T 'k03'), 'OK', 'Error') | Out-Null
    }
    catch { }
    Write-Host $missMsg
    exit 1
}






if (-not ('ScreenLockEarly' -as [type])) {
    
    try { Add-Type -Path $csEarly }
    catch {
        try {
            Add-Type -AssemblyName System.Windows.Forms
            [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, (T 'k04'), 'OK', 'Error') | Out-Null
        } catch { }
        exit 1
    }
}
$dpiOk = $false
try { $dpiOk = [ScreenLockEarly]::SetProcessDpiAwarenessContext([IntPtr]::new(-4)) } catch { }
if (-not $dpiOk) { try { [void][ScreenLockEarly]::SetProcessDPIAware() } catch { } }
try {
    $consoleHandle = [ScreenLockEarly]::GetConsoleWindow()
    if ($consoleHandle -ne [IntPtr]::Zero) {
        $consoleProcs = New-Object uint32[] 8
        $consoleCount = [ScreenLockEarly]::GetConsoleProcessList($consoleProcs, 8)
        if ($consoleCount -le 1) { [void][ScreenLockEarly]::ShowWindow($consoleHandle, 0) }
    }
}
catch { }


Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
try { [System.Windows.Forms.Application]::EnableVisualStyles() } catch { }


if (-not ('ScreenLockNative' -as [type])) {
    
    try { Add-Type -Path $csNative }
    catch {
        try {
            [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, (T 'k04'), 'OK', 'Error') | Out-Null
        } catch { }
        exit 1
    }
}







$script:StateDir = Join-Path $env:LOCALAPPDATA 'CAScreenGuard'
$script:FlagPath = Join-Path $script:StateDir 'running.flag'


$script:PresavePath = Join-Path $script:StateDir 'screen-saver-original.json'



$script:GuardLogPath = Join-Path $script:StateDir 'guard.log'


$script:LastAwakeTick = [datetime]::MinValue
$script:StartedAt = Get-Date          
$script:LastTickWall = Get-Date

function Get-LastCrashLog {
    param([datetime]$NotBefore)
    try {
        if (-not (Test-Path -LiteralPath $script:StateDir)) { return $null }
        $logs = Get-ChildItem -LiteralPath $script:StateDir -Filter 'crash-*.log' -File -ErrorAction SilentlyContinue
        if ($NotBefore -gt [datetime]::MinValue) {
            $logs = $logs | Where-Object { $_.LastWriteTime -ge $NotBefore.AddSeconds(-5) }
        }
        $f = $logs | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($f) { return $f.FullName }
    } catch { }
    return $null
}

function New-RunningFlag {
    try {
        if (-not (Test-Path -LiteralPath $script:StateDir)) { New-Item -ItemType Directory -Path $script:StateDir -Force | Out-Null }
        
        
        $info = 'started=' + (Get-Date).ToString('s') + "`r`n" +
                'user=' + $env:USERNAME + "`r`n" +
                'computer=' + $env:COMPUTERNAME + "`r`n" +
                'pid=' + $PID
        [System.IO.File]::WriteAllText($script:FlagPath, $info, (New-Object System.Text.UTF8Encoding($false)))
    } catch { }
}

function Remove-RunningFlag {
    try { if (Test-Path -LiteralPath $script:FlagPath) { Remove-Item -LiteralPath $script:FlagPath -Force } } catch { }
}

function Write-CrashLog {
    param($ErrorRecord, [string]$Where)
    try {
        if (-not (Test-Path -LiteralPath $script:StateDir)) { New-Item -ItemType Directory -Path $script:StateDir -Force | Out-Null }
        $path = Join-Path $script:StateDir ('crash-' + (Get-Date).ToString('yyyyMMdd-HHmmss') + '.log')
        $sb = New-Object System.Text.StringBuilder
        [void]$sb.AppendLine('CAScreenGuard crash log')
        [void]$sb.AppendLine('time    : ' + (Get-Date).ToString('s'))
        [void]$sb.AppendLine('where   : ' + $Where)
        [void]$sb.AppendLine('user    : ' + $env:USERNAME + ' @ ' + $env:COMPUTERNAME)
        [void]$sb.AppendLine('pid     : ' + $PID)
        [void]$sb.AppendLine('lang    : ' + $script:Lang)
        [void]$sb.AppendLine('powershell : ' + $PSVersionTable.PSVersion.ToString())
        [void]$sb.AppendLine('os      : ' + [System.Environment]::OSVersion.VersionString)
        [void]$sb.AppendLine('')
        if ($ErrorRecord) {
            [void]$sb.AppendLine('message : ' + $ErrorRecord.Exception.Message)
            [void]$sb.AppendLine('type    : ' + $ErrorRecord.Exception.GetType().FullName)
            [void]$sb.AppendLine('')
            [void]$sb.AppendLine('stack   :')
            [void]$sb.AppendLine($ErrorRecord.ScriptStackTrace)
            [void]$sb.AppendLine('')
            [void]$sb.AppendLine('detail  :')
            [void]$sb.AppendLine(($ErrorRecord | Out-String))
        }
        [System.IO.File]::WriteAllText($path, $sb.ToString(), (New-Object System.Text.UTF8Encoding($false)))
        
        Get-ChildItem -LiteralPath $script:StateDir -Filter 'crash-*.log' -File -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending | Select-Object -Skip 10 | Remove-Item -Force -ErrorAction SilentlyContinue
        return $path
    } catch { return $null }
}

function Write-TickError {
    
    
    
    param([string]$Message)
    try {
        if ([string]::IsNullOrEmpty($Message)) { return }
        if (-not (Test-Path -LiteralPath $script:StateDir)) { New-Item -ItemType Directory -Path $script:StateDir -Force | Out-Null }
        $path = Join-Path $script:StateDir 'tick-errors.log'
        if (Test-Path -LiteralPath $path) {
            if ((Get-Item -LiteralPath $path -Force).Length -gt 65536) {
                [System.IO.File]::WriteAllText($path, '', (New-Object System.Text.UTF8Encoding($false)))
            }
        }
        [System.IO.File]::AppendAllText($path,
            ((Get-Date).ToString('s') + '  ' + $Message + "`r`n"),
            (New-Object System.Text.UTF8Encoding($false)))
    } catch { }
}

function Write-GuardLog {
    
    
    
    
    param([string]$Message)
    try {
        if ([string]::IsNullOrEmpty($Message)) { return }
        if (-not (Test-Path -LiteralPath $script:StateDir)) { New-Item -ItemType Directory -Path $script:StateDir -Force | Out-Null }
        if (Test-Path -LiteralPath $script:GuardLogPath) {
            if ((Get-Item -LiteralPath $script:GuardLogPath -Force).Length -gt 65536) {
                $all = [System.IO.File]::ReadAllText($script:GuardLogPath)
                $keep = $all.Length - 32768
                if ($keep -lt 0) { $keep = 0 }
                [System.IO.File]::WriteAllText($script:GuardLogPath,
                    ("--- 日志超过 64KB，已截断，以下为最近部分 ---`r`n" + $all.Substring($keep)),
                    (New-Object System.Text.UTF8Encoding($false)))
            }
        }
        [System.IO.File]::AppendAllText($script:GuardLogPath,
            ((Get-Date).ToString('s') + '  ' + $Message + "`r`n"),
            (New-Object System.Text.UTF8Encoding($false)))
    } catch { }
}

function Test-PreviousSession {
    
    if (-not (Test-Path -LiteralPath $script:FlagPath)) { return $null }
    $res = [pscustomobject]@{ started = ''; crashLog = $null; flagTime = [datetime]::MinValue }
    try {
        $res.flagTime = (Get-Item -LiteralPath $script:FlagPath -Force).LastWriteTime
        $m = [regex]::Match([System.IO.File]::ReadAllText($script:FlagPath), 'started=([^\r\n]+)')
        if ($m.Success) { $res.started = $m.Groups[1].Value }
    } catch { }
    $res.crashLog = Get-LastCrashLog -NotBefore $res.flagTime
    return $res
}




trap {
    try { $null = Write-CrashLog -ErrorRecord $_ -Where 'trap' } catch { }
    try {
        $message = "$($_.Exception.Message)`r`n`r`n$($_.InvocationInfo.PositionMessage)"
        [System.Windows.Forms.MessageBox]::Show($message, (T 'k04'), 'OK', 'Error') | Out-Null
    }
    catch { }
    exit 1
}







try {
    [System.Windows.Forms.Application]::SetUnhandledExceptionMode([System.Windows.Forms.UnhandledExceptionMode]::CatchException)
    [System.Windows.Forms.Application]::add_ThreadException({
        param($sender, $e)
        try { Write-GuardLog ('界面线程异常（已兜住，继续运行）：' + $e.Exception.GetType().Name + ' - ' + $e.Exception.Message) } catch { }
    })
    [AppDomain]::CurrentDomain.add_UnhandledException({
        param($sender, $e)
        try { Write-GuardLog ('非界面线程异常：' + $e.ExceptionObject.GetType().Name + ' - ' + $e.ExceptionObject.Message) } catch { }
    })
} catch { }


$script:LastTickError = ''

$script:UiFamily = 'Microsoft YaHei UI'
$script:Scale = 1.0             
try { $dpiNow = [ScreenLockEarly]::GetDpiForSystem(); if ($dpiNow -gt 0) { $script:Scale = $dpiNow / 96.0 } } catch { }
$script:DlgOpen = $false          
$script:BoxState = 'normal'       


$script:ConfigFileName = '.cascreenguard.config.json'
$script:ConfigPath = $null           
$script:ConfigRaw = $null           
$script:IdleBlankMs = [int]$IdleBlankSeconds * 1000
$script:AllowClose = $false          
$script:State = 'Away'          
$script:BlankTick = [uint32]0       
$script:LastBlankSent = [datetime]::MinValue
$script:FailCount = 0
$script:TxtLockedOut     = $false          
$script:AuthLockedOut   = $false          
$script:CooldownActive = $false
$script:CooldownUntil = [datetime]::MinValue
$script:OrigScreenSaver = $null
$script:OrigScreenSaverReg = $null
$script:Restored = $false
$script:SelfTestLog = New-Object System.Collections.Generic.List[string]
$script:SelfTestFailed = $false
$script:SelfTestStep = 0




$script:ConfigCandidates = New-Object System.Collections.Generic.List[string]
$script:StoreRegPath = 'HKCU:\Software\CAScreenGuard'
try {
    $instDir = (Get-ItemProperty -LiteralPath $script:StoreRegPath -Name 'InstallDir' -ErrorAction Stop).InstallDir
    if ($instDir) { [void]$script:ConfigCandidates.Add((Join-Path $instDir $script:ConfigFileName)) }
}
catch { }
if ($script:ScriptDir) {
    [void]$script:ConfigCandidates.Add((Join-Path $script:ScriptDir $script:ConfigFileName))
}


if ($script:LangArg -eq 'zh' -or $script:LangArg -eq 'en') {
    $script:Lang = $script:LangArg
} else {
    try {
        $langSaved = (Get-ItemProperty -LiteralPath $script:StoreRegPath -Name 'Lang' -ErrorAction Stop).Lang
        if ($langSaved -eq 'zh' -or $langSaved -eq 'en') { $script:Lang = $langSaved }
    } catch { }
}


function New-RoundedPath {
    
    param([float]$x, [float]$y, [float]$w, [float]$h, [float]$r)
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $r * 2
    $p.AddArc($x, $y, $d, $d, 180, 90)
    $p.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
    $p.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
    $p.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
    $p.CloseFigure()
    return $p
}

function Get-WallpaperBitmap {
    
    
    try {
        $path = $null
        try { $path = [ScreenLockNative]::GetDesktopWallpaperPath() } catch { }
        if (-not $path -or -not (Test-Path -LiteralPath $path)) {
            
            $trans = Join-Path $env:APPDATA 'Microsoft\Windows\Themes\TranscodedWallpaper'
            if (Test-Path -LiteralPath $trans) { $path = $trans }
        }
        if (-not $path) { return $null }

        $src = $null
        try { $src = [System.Drawing.Image]::FromFile($path) } catch { return $null }
        try {
            $vw = $script:Form.Bounds.Width
            $vh = $script:Form.Bounds.Height
            if ($vw -le 0 -or $vh -le 0 -or $src.Width -le 0 -or $src.Height -le 0) { return $null }
            $out = New-Object System.Drawing.Bitmap($vw, $vh, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
            $g = [System.Drawing.Graphics]::FromImage($out)
            try {
                $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                
                $s = [Math]::Max($vw / [double]$src.Width, $vh / [double]$src.Height)
                $dw = [int][Math]::Ceiling($src.Width * $s)
                $dh = [int][Math]::Ceiling($src.Height * $s)
                $g.DrawImage($src, (New-Object System.Drawing.Rectangle([int](($vw - $dw) / 2), [int](($vh - $dh) / 2), $dw, $dh)))
                
                $shade = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(176, 0, 0, 0))
                $g.FillRectangle($shade, 0, 0, $vw, $vh)
                $shade.Dispose()
            }
            finally { $g.Dispose() }
            return $out
        }
        finally { $src.Dispose() }
    }
    catch { return $null }
}

function Install-WallpaperBackground {
    
    
    
    try {
        $script:Wallpaper = Get-WallpaperBitmap
        if (-not $script:Wallpaper) { return }
        
        
        
        try {
            $r = [int](18 * $script:Scale)
            if ($r -lt 12) { $r = 12 }
            
            $path = New-RoundedPath $card.Left $card.Top $card.Width $card.Height $r
            $g = [System.Drawing.Graphics]::FromImage($script:Wallpaper)
            try {
                $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
                $deep = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(216, 0, 0, 0))
                $g.FillPath($deep, $path)
                $deep.Dispose()
            }
            finally { $g.Dispose() }
            $path.Dispose()
        } catch { }
        $script:Form.BackgroundImageLayout = [System.Windows.Forms.ImageLayout]::None
        $script:Form.BackgroundImage = $script:Wallpaper
        
        
        $card.BackColor = [System.Drawing.Color]::Transparent
        try { $logoMark.BackColor = [System.Drawing.Color]::Transparent } catch { }
        if ($script:Form.Visible) { $script:Form.Invalidate(); $script:Form.Update() }
    } catch { }
}




function Invoke-UnlockTransition {
    param([switch]$SkipWait)
    try {
        if (-not $SkipWait) {
            
            
            Start-Sleep -Milliseconds 150
            [System.Windows.Forms.Application]::DoEvents()
        }
        $steps = 16
        for ($i = 1; $i -le $steps; $i++) {
            $t = $i / [double]$steps
            $alpha = 1.0 - [Math]::Pow($t, 0.7)     
            if ($alpha -lt 0.04) { $alpha = 0.04 }
            $script:Form.Opacity = $alpha
            [System.Windows.Forms.Application]::DoEvents()
            Start-Sleep -Milliseconds 45
        }
    }
    catch {
        
        try { $script:Form.Opacity = 1.0 } catch { }
    }
}

function Invoke-Sound {
    param([string]$Kind)
    try {
        switch ($Kind) {
            'error' { [System.Media.SystemSounds]::Hand.Play() }
            'warn' { [System.Media.SystemSounds]::Exclamation.Play() }
            'ok' { }   
        }
    }
    catch { }
}

function Show-ErrorMsg {
    param([string]$Text, [switch]$Info)
    $script:TxtError.Text = $Text
    if (-not $script:TxtError.Visible) { $script:TxtError.Visible = $true }
    
    if (-not $Info) {
        $script:BoxState = 'error'
        try { $script:BoxPanel.Invalidate() } catch { }
    }
}

function Show-LockNotice {
    
    try { $script:LockNotice.Visible = $true } catch { }
    try { $script:Footer1.Visible = $false } catch { }
    try { $script:Footer2.Visible = $false } catch { }
}

function Hide-ErrorMsg {
    if ($script:BoxState -ne 'locked') { $script:BoxState = 'normal' }
    try { $script:BoxPanel.Invalidate() } catch { }
    if ($script:TxtError -and $script:TxtError.Visible) { $script:TxtError.Visible = $false }
}

function Set-AuthLockedUI {
    
    
    param($Dlg, $Tip, [switch]$Permanent)
    try {
        $body = (T 'k59')
        
        
        if ($Permanent) { $body += "`r`n" + (T 'k75') }
        $body += "`r`n`r`n" + (T 'k65')
        if ($Permanent) { $body += "`r`n" + (T 'k67') }
        $Tip.Text = $body + "`r`n" + (T 'k64')
        $Tip.ForeColor = [System.Drawing.Color]::FromArgb(192, 57, 43)
        $k = $script:Scale
        if ($k -lt 1) { $k = 1 }
        
        $need = [System.Windows.Forms.TextRenderer]::MeasureText(
            $Tip.Text, $Tip.Font,
            (New-Object System.Drawing.Size([Math]::Max(60, $Tip.Width - [int](8 * $k)), 4000)),
            [System.Windows.Forms.TextFormatFlags]::WordBreak).Height + [int](12 * $k)
        $Tip.SetBounds($Tip.Left, $Tip.Top, $Tip.Width, $need)
        
        $wantH = $Tip.Top + $need + [int](18 * $k)
        if ($Dlg.ClientSize.Height -lt $wantH) {
            $Dlg.ClientSize = New-Object System.Drawing.Size($Dlg.ClientSize.Width, $wantH)
        }
        
        $script:TxtLockedOut = $true
        $script:BoxState = 'locked'
        try { $script:Txt.Enabled = $false } catch { }
        try {
            $script:BoxPanel.BackColor = [System.Drawing.Color]::FromArgb(16, 16, 18)
            $script:Txt.BackColor = $script:BoxPanel.BackColor
            $script:BoxPanel.Invalidate()
        } catch { }
        Show-LockNotice
        foreach ($c in $Dlg.Controls) {
            if ($c -is [System.Windows.Forms.TextBox]) { $c.Enabled = $false; $c.Text = '' }
            
            
            elseif ($c -is [System.Windows.Forms.Button] -and $c.Tag -ne 'dismiss') {
                $c.Enabled = $false
                $c.BackColor = [System.Drawing.Color]::FromArgb(214, 216, 220)
                $c.ForeColor = [System.Drawing.Color]::FromArgb(150, 152, 156)
            }
        }
    } catch { }
}

function Test-AuthCode {
    
    
    param([string]$Code, $Source)
    try {
        if ($null -eq $Source) { $Source = $script:Config }
        if (-not $Source -or -not $Source.authHash) { return $false }
        $code = $Code.Trim()
        if ([string]::IsNullOrEmpty($code)) { return $false }
        $iterations = 120000
        if ($Source.authIterations) { $iterations = [int]$Source.authIterations }
        $salt = [Convert]::FromBase64String($Source.authSalt)
        
        $derive = [System.Security.Cryptography.Rfc2898DeriveBytes]::new($code, $salt, $iterations)
        try { $actual = $derive.GetBytes(32) } finally { $derive.Dispose() }
        $expect = [Convert]::FromBase64String($Source.authHash)
        if ($actual.Length -ne $expect.Length) { return $false }
        $diff = 0
        for ($i = 0; $i -lt $actual.Length; $i++) { $diff = $diff -bor ($actual[$i] -bxor $expect[$i]) }
        return ($diff -eq 0)
    }
    catch { return $false }
}

function Test-PlainAscii {
    
    
    param([string]$Text)
    if ([string]::IsNullOrEmpty($Text)) { return $false }
    foreach ($ch in $Text.ToCharArray()) {
        $code = [int][char]$ch
        if (($code -lt 33) -or ($code -gt 126)) { return $false }
    }
    return $true
}

function Test-NewPasswordInput {
    
    
    param([string]$First, [string]$Second, [string]$KeyTooShort, [string]$KeyNotAscii, [string]$KeyMismatch)
    if ($First.Length -lt 4) { return [pscustomobject]@{ Message = (T $KeyTooShort); Field = 1 } }
    if (-not (Test-PlainAscii $First)) { return [pscustomobject]@{ Message = (T $KeyNotAscii); Field = 1 } }
    
    if ($First -cne $Second) { return [pscustomobject]@{ Message = (T $KeyMismatch); Field = 2 } }
    return [pscustomobject]@{ Message = ''; Field = 1 }
}

function Show-DialogError {
    
    param($Label, [string]$Message)
    $Label.Text = $Message
    $Label.Visible = $true
}

function Set-DialogDpi {
    
    
    
    param($Dlg, [string]$Family, [float]$BasePt, $Items)
    if ($script:Scale -le 1.01) { return }
    $Dlg.Scale((New-Object System.Drawing.SizeF([float]$script:Scale, [float]$script:Scale)))
    $Dlg.Font = New-Object System.Drawing.Font($Family, [float]$BasePt)
    foreach ($it in $Items) {
        if ($it.Style) { $it.Control.Font = New-Object System.Drawing.Font($Family, [float]$it.Pt, $it.Style) }
        else { $it.Control.Font = New-Object System.Drawing.Font($Family, [float]$it.Pt) }
    }
}


function Read-PasswordConfig {
    
    
    $script:ConfigPath = $null
    $script:ConfigRaw = $null
    foreach ($path in $script:ConfigCandidates) {
        if (-not $path) { continue }
        if (-not (Test-Path -LiteralPath $path)) { continue }
        try {
            $json = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
            $cfg = $json | ConvertFrom-Json
            if ($cfg.salt -and $cfg.hash -and $cfg.iterations) {
                $script:ConfigPath = $path
                $script:ConfigRaw = $json
                return $cfg
            }
        }
        catch { }
    }
    return $null
}

function Save-PasswordConfig {
    
    
    
    param($Record, $Store)
    $body = [pscustomobject]@{
        version        = $Record.version
        algorithm      = $Record.algorithm
        iterations     = $Record.iterations
        salt           = $Record.salt
        hash           = $Record.hash
        authIterations = $Record.authIterations
        authSalt       = $Record.authSalt
        authHash       = $Record.authHash
        authHint       = $Record.authHint
        created        = $Record.created
        marker         = ''
    }
    $text = $body | ConvertTo-Json -Compress -Depth 4
    if ($null -eq $Store) { $Store = Read-IntegrityStore }
    
    
    
    if ($Store -and $Store.markerKey) {
        $text = [regex]::Replace($text, '"marker"\s*:\s*""',
            ('"marker":"' + (Get-ConfigMarker -Text $text -KeyB64 $Store.markerKey) + '"'))
    }
    foreach ($path in $script:ConfigCandidates) {
        if (-not $path) { continue }
        try {
            $dir = Split-Path -Parent $path
            if ($dir -and -not (Test-Path -LiteralPath $dir)) {
                New-Item -ItemType Directory -Path $dir -Force | Out-Null
            }
            
            
            if (Test-Path -LiteralPath $path) {
                try { (Get-Item -LiteralPath $path -Force).Attributes = [System.IO.FileAttributes]::Normal } catch { }
            }
            [System.IO.File]::WriteAllText($path, $text, (New-Object System.Text.UTF8Encoding($false)))
            try { (Get-Item -LiteralPath $path -Force).Attributes = [System.IO.FileAttributes]::Hidden } catch { }
            $script:ConfigPath = $path
            $script:ConfigRaw = $text
            return $path
        }
        catch { }
    }
    throw (T 'k05')
}

function New-PasswordRecord {
    
    param([string]$Password, $Auth)
    if ($null -eq $Auth) { $Auth = Read-IntegrityStore }
    if ($null -eq $Auth) { $Auth = $script:Config }
    $salt = New-Object byte[] 16
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try { $rng.GetBytes($salt) } finally { $rng.Dispose() }
    $iterations = 120000
    $derive = [System.Security.Cryptography.Rfc2898DeriveBytes]::new($Password, $salt, $iterations)
    try { $hash = $derive.GetBytes(32) } finally { $derive.Dispose() }

    $authSaltB64 = ''
    $authHashB64 = ''
    $authIterations = 120000
    $authHintText = ''
    if ($Auth) {
        if ($Auth.authSalt) { $authSaltB64 = [string]$Auth.authSalt }
        if ($Auth.authHash) { $authHashB64 = [string]$Auth.authHash }
        if ($Auth.authIterations) { $authIterations = [int]$Auth.authIterations }
        if ($Auth.authHint) { $authHintText = [string]$Auth.authHint }
    }

    return [pscustomobject]@{
        version        = 2
        algorithm      = 'PBKDF2-SHA1'
        iterations     = $iterations
        salt           = [Convert]::ToBase64String($salt)
        hash           = [Convert]::ToBase64String($hash)
        authIterations = $authIterations
        authSalt       = $authSaltB64
        authHash       = $authHashB64
        authHint       = $authHintText
        created        = (Get-Date).ToString('s')
        marker         = ''
    }
}

function Test-PasswordRecord {
    param([string]$Password, $Record)
    try {
        $salt = [Convert]::FromBase64String($Record.salt)
        $derive = [System.Security.Cryptography.Rfc2898DeriveBytes]::new($Password, $salt, [int]$Record.iterations)
        try { $actual = $derive.GetBytes(32) } finally { $derive.Dispose() }
        $expect = [Convert]::FromBase64String($Record.hash)
        if ($actual.Length -ne $expect.Length) { return $false }
        $diff = 0
        for ($i = 0; $i -lt $actual.Length; $i++) { $diff = $diff -bor ($actual[$i] -bxor $expect[$i]) }
        return ($diff -eq 0)
    }
    catch { return $false }
}









$script:StoreRegPath = 'HKCU:\Software\CAScreenGuard'
$script:StoreMirrorPath = Join-Path (Join-Path $env:APPDATA 'CAScreenGuard') 'store.json'

function Get-ConfigCanonical {
    
    param([string]$Text)
    return [regex]::Replace($Text, '"marker":"[^"]*"', '"marker":""')
}

function Get-ConfigMarker {
    param([string]$Text, [string]$KeyB64)
    $key = [Convert]::FromBase64String($KeyB64)
    $hmac = [System.Security.Cryptography.HMACSHA256]::new($key)
    try {
        $data = [System.Text.Encoding]::UTF8.GetBytes($Text)
        return [Convert]::ToBase64String($hmac.ComputeHash($data))
    } finally { $hmac.Dispose() }
}

function Read-IntegrityStore {
    
    try {
        if (Test-Path -LiteralPath $script:StoreRegPath) {
            $v = Get-ItemProperty -LiteralPath $script:StoreRegPath -ErrorAction Stop
            if ($v.Token -and $v.MarkerKey) {
                return [pscustomobject]@{
                    token          = $v.Token
                    markerKey      = $v.MarkerKey
                    authSalt       = $v.AuthSalt
                    authHash       = $v.AuthHash
                    authIterations = $v.AuthIterations
                    authHint       = $v.AuthHint
                    provisioned    = $v.Provisioned
                }
            }
        }
    }
    catch { }
    try {
        if (Test-Path -LiteralPath $script:StoreMirrorPath) {
            $j = [System.IO.File]::ReadAllText($script:StoreMirrorPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
            if ($j.token -and $j.markerKey) { return $j }
        }
    }
    catch { }
    return $null
}





$script:AuthBanRegName = 'AuthBan'
$script:AuthBanMirrorPath = Join-Path (Join-Path $env:APPDATA 'CAScreenGuard') 'authban.txt'

function Test-AuthBanned {
    try {
        $v = Get-ItemProperty -LiteralPath $script:StoreRegPath -ErrorAction Stop
        if ($v.AuthBan) { return $true }
    }
    catch { }
    try { if (Test-Path -LiteralPath $script:AuthBanMirrorPath) { return $true } } catch { }
    return $false
}

function Set-AuthBanned {
    $stamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    try {
        if (-not (Test-Path -LiteralPath $script:StoreRegPath)) { New-Item -Path $script:StoreRegPath -Force | Out-Null }
        New-ItemProperty -LiteralPath $script:StoreRegPath -Name $script:AuthBanRegName -Value $stamp -PropertyType String -Force | Out-Null
    }
    catch { }
    try {
        $dir = Split-Path -Parent $script:AuthBanMirrorPath
        if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        [System.IO.File]::WriteAllText($script:AuthBanMirrorPath, $stamp, (New-Object System.Text.UTF8Encoding($false)))
    }
    catch { }
}



$script:AuthBanned = Test-AuthBanned
if ($script:AuthBanned) { $script:AuthLockedOut = $true }

function Write-IntegrityStore {
    param($Store)
    $json = $Store | ConvertTo-Json -Compress -Depth 4
    $ok = $false
    try {
        if (-not (Test-Path -LiteralPath $script:StoreRegPath)) { New-Item -Path $script:StoreRegPath -Force | Out-Null }
        New-ItemProperty -LiteralPath $script:StoreRegPath -Name 'Token' -Value $Store.token -PropertyType String -Force | Out-Null
        New-ItemProperty -LiteralPath $script:StoreRegPath -Name 'MarkerKey' -Value $Store.markerKey -PropertyType String -Force | Out-Null
        New-ItemProperty -LiteralPath $script:StoreRegPath -Name 'AuthSalt' -Value ([string]$Store.authSalt) -PropertyType String -Force | Out-Null
        New-ItemProperty -LiteralPath $script:StoreRegPath -Name 'AuthHash' -Value ([string]$Store.authHash) -PropertyType String -Force | Out-Null
        New-ItemProperty -LiteralPath $script:StoreRegPath -Name 'AuthIterations' -Value ([string]$Store.authIterations) -PropertyType String -Force | Out-Null
        New-ItemProperty -LiteralPath $script:StoreRegPath -Name 'AuthHint' -Value ([string]$Store.authHint) -PropertyType String -Force | Out-Null
        New-ItemProperty -LiteralPath $script:StoreRegPath -Name 'Provisioned' -Value ([string]$Store.provisioned) -PropertyType String -Force | Out-Null
        $ok = $true
    }
    catch { }
    try {
        $dir = Split-Path -Parent $script:StoreMirrorPath
        if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        [System.IO.File]::WriteAllText($script:StoreMirrorPath, $json, (New-Object System.Text.UTF8Encoding($false)))
        $ok = $true
    }
    catch { }
    return $ok
}

function New-IntegrityStore {
    $raw = New-Object byte[] 32
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try { $rng.GetBytes($raw) } finally { $rng.Dispose() }
    return [pscustomobject]@{
        token          = [guid]::NewGuid().ToString('N')
        markerKey      = [Convert]::ToBase64String($raw)
        authSalt       = ''
        authHash       = ''
        authIterations = ''
        authHint       = ''
        provisioned    = (Get-Date).ToString('s')
    }
}

function Test-ConfigIntegrity {
    
    
    param($ConfigRecord, [string]$RawText)
    $store = Read-IntegrityStore
    if ($null -eq $store) {
        if ($null -eq $ConfigRecord) { return 'fresh' }
        return 'unprovable'
    }
    if ($null -eq $ConfigRecord) { return 'deleted' }
    if (-not $ConfigRecord.marker) { return 'modified' }
    if ([string]::IsNullOrEmpty($RawText)) { return 'modified' }
    $canonical = Get-ConfigCanonical -Text $RawText
    
    if ((Get-ConfigMarker -Text $canonical -KeyB64 $store.markerKey) -cne $ConfigRecord.marker) { return 'modified' }
    return 'ok'
}


function Invoke-GoDark {
    
    $script:State = 'Away'
    $script:BlankTick = [ScreenLockNative]::GetLastInputTick()
    $script:LastBlankSent = Get-Date
    [ScreenLockNative]::MonitorOff()
}

function Update-CooldownMessage {
    if (-not $script:CooldownActive) { return }
    $now = Get-Date
    if ($now -lt $script:CooldownUntil) {
        $left = [int][Math]::Ceiling(($script:CooldownUntil - $now).TotalSeconds)
        if ($left -lt 1) { $left = 1 }
        Show-ErrorMsg ((T 'k06') -f $left)
    }
    else {
        $script:CooldownActive = $false
        Hide-ErrorMsg
    }
}

function Invoke-SubmitAttempt {
    if ($script:AllowClose) { return }
    if ($script:TxtLockedOut) { return }        

    $now = Get-Date
    if ($script:CooldownActive -and $now -lt $script:CooldownUntil) {
        $left = [Math]::Max(1, [int][Math]::Ceiling(($script:CooldownUntil - $now).TotalSeconds))
        Show-ErrorMsg ((T 'k06') -f $left)
        Invoke-Sound 'warn'
        return
    }

    $typed = $script:Txt.Text
    if ([string]::IsNullOrEmpty($typed)) { return }   

    if (Test-PasswordRecord -Password $typed -Record $script:Config) {
        $script:FailCount = 0
        $script:AllowClose = $true
        [ScreenLockNative]::MonitorOn()
        $script:Timer.Stop()
        
        Invoke-UnlockTransition -SkipWait:$SelfTest
        $script:Form.Close()
        return
    }

    
    $script:FailCount++
    
    if ($script:FailCount -ge 8) {
        $script:TxtLockedOut = $true
        $script:CooldownActive = $false
        try { $script:Txt.Enabled = $false } catch { }
        
        $script:BoxState = 'locked'
        try {
            $script:BoxPanel.BackColor = [System.Drawing.Color]::FromArgb(16, 16, 18)
            $script:Txt.BackColor = $script:BoxPanel.BackColor
            $script:BoxPanel.Invalidate()
        } catch { }
        Hide-ErrorMsg
        Show-LockNotice
        Invoke-Sound 'error'
        return
    }
    $script:Txt.Clear()
    Invoke-Sound 'error'
    $wait = 0
    if ($script:FailCount -ge 3) {
        $wait = [int][Math]::Min(30, 3 * [Math]::Pow(2, $script:FailCount - 3))
    }
    if ($wait -gt 0) {
        $script:CooldownUntil = (Get-Date).AddSeconds($wait)
        $script:CooldownActive = $true
        Show-ErrorMsg ((T 'k08') -f $wait)
    }
    else {
        Show-ErrorMsg (T 'k09')
    }
}

function Invoke-GuardTick {
    try {
        if ($script:AllowClose) { return }
        $now = Get-Date

        
        
        
        $gap = ($now - $script:LastTickWall).TotalSeconds
        if ($gap -gt 5) {
            Write-GuardLog ('定时器中断 {0:N1} 秒，按"可能刚从睡眠/休眠恢复"处理：重新保持唤醒并复位遮罩' -f $gap)
            try { $null = [ScreenLockNative]::KeepSystemAwake() } catch { }
            $script:LastAwakeTick = $now
            try { [ScreenLockNative]::ReassertTopMost($script:Form.Handle) } catch { }
            if ($script:State -eq 'Away') {
                $script:BlankTick = [ScreenLockNative]::GetLastInputTick()
                $script:LastBlankSent = $now
                try { [ScreenLockNative]::MonitorOff() } catch { }
            }
        }
        $script:LastTickWall = $now

        
        
        if (($now - $script:LastAwakeTick).TotalSeconds -ge 30) {
            $script:LastAwakeTick = $now
            $awakeOk = $false
            try { $awakeOk = [ScreenLockNative]::KeepSystemAwake() } catch { $awakeOk = $false }
            if (-not $awakeOk) { Write-GuardLog '唤醒请求重发失败（SetThreadExecutionState 返回 0）' }
        }

        $idle = [uint32][ScreenLockNative]::GetIdleMilliseconds()

        if ($script:State -eq 'Away') {
            if ([ScreenLockNative]::GetLastInputTick() -ne $script:BlankTick) {
                
                $script:State = 'Prompt'
                $script:LastBlankSent = [datetime]::MinValue
            }
            elseif ((($now - $script:LastBlankSent).TotalSeconds -ge 10) -and ($idle -ge 3000)) {
                
                $script:BlankTick = [ScreenLockNative]::GetLastInputTick()
                $script:LastBlankSent = $now
                [ScreenLockNative]::MonitorOff()
            }
        }
        else {
            if (($idle -ge $script:IdleBlankMs) -and (-not $script:DlgOpen)) { Invoke-GoDark }
        }

        Update-CooldownMessage
        Update-Clock

        
        if (-not $script:DlgOpen) {
            
            
            
            
            
            [ScreenLockNative]::ReassertTopMost($script:Form.Handle)
            $tickOk = ([ScreenLockNative]::GetLastInputTick() -ne [uint32]::MaxValue)
            if ($tickOk -and ($idle -lt 2000) -and ([ScreenLockNative]::ForegroundWindow -ne $script:Form.Handle)) {
                [ScreenLockNative]::ForceForeground($script:Form.Handle)
            }
            if ($script:Txt.Enabled -and (-not $script:Txt.Focused)) { $null = $script:Txt.Focus() }
        }
    }
    catch {
        
        $msg = $_.Exception.Message
        if ($msg -ne $script:LastTickError) {
            $script:LastTickError = $msg
            Write-TickError -Message $msg
        }
    }
}


function Restore-PendingScreenSaverSave {
    
    
    try {
        if (-not (Test-Path -LiteralPath $script:PresavePath)) { return }
        $saved = [System.IO.File]::ReadAllText($script:PresavePath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
        if ($null -ne $saved.reg) {
            Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name ScreenSaveActive -Value $saved.reg -ErrorAction SilentlyContinue
        }
        if ($null -ne $saved.spi) { [ScreenLockNative]::SetScreenSaverActive(([int]$saved.spi) -ne 0) }
        Remove-Item -LiteralPath $script:PresavePath -Force -ErrorAction SilentlyContinue
    } catch { }
}

function Save-ScreenSaverPrerestore {
    try {
        if (-not (Test-Path -LiteralPath $script:StateDir)) { New-Item -ItemType Directory -Path $script:StateDir -Force | Out-Null }
        $o = [pscustomobject]@{
            reg     = $script:OrigScreenSaverReg
            spi     = $script:OrigScreenSaver
            savedAt = (Get-Date).ToString('s')
        }
        [System.IO.File]::WriteAllText($script:PresavePath, ($o | ConvertTo-Json -Compress), (New-Object System.Text.UTF8Encoding($false)))
    } catch { }
}

function Initialize-SystemState {
    Restore-PendingScreenSaverSave          
    try { $script:OrigScreenSaver = [ScreenLockNative]::GetScreenSaverActive() } catch { $script:OrigScreenSaver = $null }
    try {
        $script:OrigScreenSaverReg = (Get-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name ScreenSaveActive -ErrorAction Stop).ScreenSaveActive
    }
    catch { $script:OrigScreenSaverReg = $null }
    Save-ScreenSaverPrerestore              
    try { [ScreenLockNative]::SetScreenSaverActive($false) } catch { }
    
    
    try { $null = [ScreenLockNative]::KeepSystemAwake() } catch { }
    $script:LastAwakeTick = Get-Date
    
    
    
    if (-not $NoKeyboardHook) {
        try { $null = [ScreenLockNative]::InstallKeyboardHook() } catch { }
        try { [ScreenLockNative]::BlockSystemKeys = $true } catch { }
    }
}

function Restore-SystemState {
    if ($script:Restored) { return }
    $script:Restored = $true
    
    try { [ScreenLockNative]::BlockSystemKeys = $false } catch { }
    try { [ScreenLockNative]::RemoveKeyboardHook() } catch { }
    
    try { [ScreenLockNative]::TargetWindow = [IntPtr]::Zero } catch { }
    Remove-RunningFlag                        
    try { [ScreenLockNative]::MonitorOn() } catch { }
    
    try {
        $deadline = (Get-Date).AddSeconds(1.2)
        while ((Get-Date) -lt $deadline) {
            [System.Windows.Forms.Application]::DoEvents()
            Start-Sleep -Milliseconds 40
        }
    }
    catch { }
    try {
        if ($null -ne $script:OrigScreenSaver) {
            [ScreenLockNative]::SetScreenSaverActive(([int]$script:OrigScreenSaver) -ne 0)
        }
    }
    catch { }
    try {
        if ($null -ne $script:OrigScreenSaverReg) {
            $current = $null
            try {
                $current = (Get-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name ScreenSaveActive -ErrorAction Stop).ScreenSaveActive
            }
            catch { }
            if ("$current" -ne "$($script:OrigScreenSaverReg)") {
                Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name ScreenSaveActive -Value $script:OrigScreenSaverReg -ErrorAction SilentlyContinue
            }
        }
    }
    catch { }
    try { Remove-Item -LiteralPath $script:PresavePath -Force -ErrorAction SilentlyContinue } catch { }
    try { $null = [ScreenLockNative]::ReleaseKeepAwake() } catch { }
}




function Show-ChangePasswordDialog {
    
    $family = $script:UiFamily
    $script:CpwResult = 'cancel'
    $script:CpwAuthFails = 0
    $script:CpwErr = $null

    
    if (-not $script:Config -or -not $script:Config.authHash) {
        [System.Windows.Forms.MessageBox]::Show((T 'k10'), 'CAScreenGuard', 'OK', 'Warning') | Out-Null
        return 'noauth'
    }
    $hintText = (T 'k11')
    if ($script:Config.authHint) { $hintText = $script:Config.authHint }

    $script:CpwDlg = New-Object System.Windows.Forms.Form
    $script:CpwDlg.Text = (T 'k12')
    $script:CpwDlg.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $script:CpwDlg.MaximizeBox = $false
    $script:CpwDlg.MinimizeBox = $false
    $script:CpwDlg.TopMost = $true
    $script:CpwDlg.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    $script:CpwDlg.ClientSize = New-Object System.Drawing.Size(520, 392)
    $script:CpwDlg.BackColor = [System.Drawing.Color]::FromArgb(249, 249, 251)
    $script:CpwDlg.Font = New-Object System.Drawing.Font($family, [float]9)
    try {
        $icoFile = Join-Path $script:ScriptDir 'CAScreenGuard.ico'
        if (Test-Path -LiteralPath $icoFile) { $script:CpwDlg.Icon = New-Object System.Drawing.Icon($icoFile, 32, 32) }
    }
    catch { }

    $head = New-Object System.Windows.Forms.Label
    $head.AutoSize = $false
    $head.Text = (T 'k13')
    $head.Font = New-Object System.Drawing.Font($family, [float]15, [System.Drawing.FontStyle]::Bold)
    $head.ForeColor = [System.Drawing.Color]::FromArgb(28, 28, 32)
    $head.SetBounds(24, 18, 472, 34)
    $script:CpwDlg.Controls.Add($head)

    $desc = New-Object System.Windows.Forms.Label
    $desc.AutoSize = $false
    $desc.Text = ((T 'k14') -f $hintText)
    $desc.ForeColor = [System.Drawing.Color]::FromArgb(96, 100, 108)
    $desc.SetBounds(24, 52, 472, 42)
    $script:CpwDlg.Controls.Add($desc)

    $lb0 = New-Object System.Windows.Forms.Label
    $lb0.AutoSize = $false
    $lb0.Text = (T 'k15')
    $lb0.ForeColor = [System.Drawing.Color]::FromArgb(70, 74, 80)
    $lb0.SetBounds(24, 102, 472, 20)
    $script:CpwDlg.Controls.Add($lb0)

    $script:CpwAuth = New-Object System.Windows.Forms.TextBox
    $script:CpwAuth.PasswordChar = [char]0x25CF
    $script:CpwAuth.ImeMode = [System.Windows.Forms.ImeMode]::Disable
    $script:CpwAuth.MaxLength = 128
    $script:CpwAuth.SetBounds(24, 124, 472, 26)
    $script:CpwDlg.Controls.Add($script:CpwAuth)

    $lb1 = New-Object System.Windows.Forms.Label
    $lb1.AutoSize = $false
    $lb1.Text = (T 'k16')
    $lb1.ForeColor = [System.Drawing.Color]::FromArgb(70, 74, 80)
    $lb1.SetBounds(24, 162, 472, 20)
    $script:CpwDlg.Controls.Add($lb1)

    $script:CpwPwd1 = New-Object System.Windows.Forms.TextBox
    $script:CpwPwd1.PasswordChar = [char]0x25CF
    $script:CpwPwd1.ImeMode = [System.Windows.Forms.ImeMode]::Disable
    $script:CpwPwd1.MaxLength = 128
    $script:CpwPwd1.SetBounds(24, 184, 472, 26)
    $script:CpwDlg.Controls.Add($script:CpwPwd1)

    $lb2 = New-Object System.Windows.Forms.Label
    $lb2.AutoSize = $false
    $lb2.Text = (T 'k17')
    $lb2.ForeColor = [System.Drawing.Color]::FromArgb(70, 74, 80)
    $lb2.SetBounds(24, 222, 472, 20)
    $script:CpwDlg.Controls.Add($lb2)

    $script:CpwPwd2 = New-Object System.Windows.Forms.TextBox
    $script:CpwPwd2.PasswordChar = [char]0x25CF
    $script:CpwPwd2.ImeMode = [System.Windows.Forms.ImeMode]::Disable
    $script:CpwPwd2.MaxLength = 128
    $script:CpwPwd2.SetBounds(24, 244, 472, 26)
    $script:CpwDlg.Controls.Add($script:CpwPwd2)

    $err = New-Object System.Windows.Forms.Label
    $err.AutoSize = $false
    $err.ForeColor = [System.Drawing.Color]::FromArgb(206, 55, 55)
    $err.SetBounds(24, 280, 472, 20)
    $err.Visible = $false
    $script:CpwErr = $err
    $script:CpwDlg.Controls.Add($err)

    $save = New-Object System.Windows.Forms.Button
    $save.Text = (T 'k18')
    $save.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $save.FlatAppearance.BorderSize = 0
    $save.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 212)
    $save.ForeColor = [System.Drawing.Color]::White
    $save.Font = New-Object System.Drawing.Font($family, [float]10)
    $save.SetBounds(312, 324, 88, 32)
    $script:CpwDlg.Controls.Add($save)

    $cancel = New-Object System.Windows.Forms.Button
    $cancel.Text = (T 'k19')
    $cancel.Tag = 'dismiss'          
    $cancel.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $cancel.FlatAppearance.BorderSize = 0
    $cancel.BackColor = [System.Drawing.Color]::FromArgb(232, 233, 237)
    $cancel.ForeColor = [System.Drawing.Color]::FromArgb(40, 40, 44)
    $cancel.Font = New-Object System.Drawing.Font($family, [float]10)
    $cancel.SetBounds(416, 324, 88, 32)
    $script:CpwDlg.Controls.Add($cancel)

    
    $script:CpwTip = New-Object System.Windows.Forms.Label
    $script:CpwTip.AutoSize = $false
    $script:CpwTip.Text = ''
    $script:CpwTip.ForeColor = [System.Drawing.Color]::FromArgb(150, 154, 160)
    $script:CpwTip.Font = New-Object System.Drawing.Font($family, [float]8.5)
    $script:CpwTip.SetBounds(24, 366, 480, 116)
    $script:CpwDlg.Controls.Add($script:CpwTip)

    $script:CpwDlg.AcceptButton = $save
    $script:CpwDlg.CancelButton = $cancel
    $script:CpwDlg.Add_Shown({ $null = $script:CpwAuth.Focus() })
    if ($script:AuthLockedOut) { Set-AuthLockedUI -Dlg $script:CpwDlg -Tip $script:CpwTip -Permanent:$script:AuthBanned }

    $save.Add_Click({
            if (-not (Test-AuthCode $script:CpwAuth.Text)) {
                $script:CpwAuthFails++
                if ($script:CpwAuthFails -ge 3) {
                    $script:CpwAuthFails = 0
                    $script:AuthLockedOut = $true
                    $script:CpwResult = 'toomany'   
                    Set-AuthLockedUI -Dlg $script:CpwDlg -Tip $script:CpwTip -Permanent:$script:AuthBanned
                    return
                }
                
                $script:CpwErr.Visible = $false
                $script:CpwAuth.Clear()
                $null = $script:CpwAuth.Focus()
                return
            }
            $check = Test-NewPasswordInput -First $script:CpwPwd1.Text -Second $script:CpwPwd2.Text `
                -KeyTooShort 'k21' -KeyNotAscii 'k22' -KeyMismatch 'k23'
            if ($check.Message.Length -gt 0) {
                Show-DialogError -Label $script:CpwErr -Message $check.Message
                if ($check.Field -eq 2) { $script:CpwPwd2.Clear(); $null = $script:CpwPwd2.Focus() }
                else { $null = $script:CpwPwd1.Focus() }
                return
            }
            try {
                $record = New-PasswordRecord -Password $a
                $null = Save-PasswordConfig -Record $record
                $script:Config = $record
                $script:CpwResult = 'ok'
            }
            catch {
                $script:CpwErr.Text = (T 'k24') + $_.Exception.Message
                $script:CpwErr.Visible = $true
                return
            }
            $script:CpwDlg.DialogResult = [System.Windows.Forms.DialogResult]::OK
        })
    $cancel.Add_Click({
            
            if ($script:CpwResult -ne 'toomany') { $script:CpwResult = 'cancel' }
            $script:CpwDlg.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        })
    $script:CpwAuth.Add_TextChanged({ if ($script:CpwErr.Visible) { $script:CpwErr.Visible = $false } })
    $script:CpwPwd1.Add_TextChanged({ if ($script:CpwErr.Visible) { $script:CpwErr.Visible = $false } })
    $script:CpwPwd2.Add_TextChanged({ if ($script:CpwErr.Visible) { $script:CpwErr.Visible = $false } })

    Set-DialogDpi -Dlg $script:CpwDlg -Family $family -BasePt 9 -Items @(
        @{ Control = $head; Pt = 15; Style = [System.Drawing.FontStyle]::Bold },
        @{ Control = $desc; Pt = 9 },
        @{ Control = $save; Pt = 10 },
        @{ Control = $cancel; Pt = 10 })

    $null = $script:CpwDlg.ShowDialog()
    try { $script:CpwDlg.Dispose() } catch { }
    $script:CpwDlg = $null
    $script:CpwAuth = $null
    $script:CpwTip = $null
    $script:CpwPwd1 = $null
    $script:CpwPwd2 = $null
    $script:CpwErr = $null
    return $script:CpwResult
}

function Invoke-ChangePasswordFlow {
    if ($script:DlgOpen) { return }
    $script:DlgOpen = $true
    $outcome = 'cancel'
    try { $outcome = Show-ChangePasswordDialog } catch { $outcome = 'cancel' }
    $script:DlgOpen = $false
    try { if ($script:Txt.Enabled) { $null = $script:Txt.Focus() } } catch { }
    
    
    if ($outcome -eq 'ok') {
        try { $script:Txt.Clear() } catch { }
        Show-ErrorMsg (T 'k25') -Info
    }
    elseif ($outcome -eq 'toomany') {
        Show-ErrorMsg (T 'k26') -Info
    }
    elseif ($outcome -eq 'noauth') {
        Show-ErrorMsg (T 'k27') -Info
    }
}





function Show-RebuildDialog {
    
    
    
    $family = $script:UiFamily
    $script:DlgErr = $null
    $script:DlgFails = 0
    $script:DlgResult = 'cancel'
    
    $script:DlgStore = Read-IntegrityStore
    $hintText = (T 'k28')
    if ($script:DlgStore -and $script:DlgStore.authHint) { $hintText = $script:DlgStore.authHint }

    $script:Dlg = New-Object System.Windows.Forms.Form
    $script:Dlg.Text = (T 'k29')
    $script:Dlg.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $script:Dlg.MaximizeBox = $false
    $script:Dlg.MinimizeBox = $false
    $script:Dlg.TopMost = $true
    $script:Dlg.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    $script:Dlg.ClientSize = New-Object System.Drawing.Size(484, 456)
    $script:Dlg.BackColor = [System.Drawing.Color]::FromArgb(249, 249, 251)
    $script:Dlg.Font = New-Object System.Drawing.Font($family, [float]9)
    try {
        $icoFile = Join-Path $script:ScriptDir 'CAScreenGuard.ico'
        if (Test-Path -LiteralPath $icoFile) { $script:Dlg.Icon = New-Object System.Drawing.Icon($icoFile, 32, 32) }
    }
    catch { }

    $head = New-Object System.Windows.Forms.Label
    $head.AutoSize = $false
    $head.Text = (T 'k30')
    
    $headPt = 15
    if ($script:Lang -eq 'en') { $headPt = 13 }
    $head.Font = New-Object System.Drawing.Font($family, [float]$headPt, [System.Drawing.FontStyle]::Bold)
    $head.ForeColor = [System.Drawing.Color]::FromArgb(192, 57, 43)
    $head.SetBounds(24, 16, 436, 34)
    $script:Dlg.Controls.Add($head)

    $desc = New-Object System.Windows.Forms.Label
    $desc.AutoSize = $false
    $desc.Text = ((T 'k31') +
        (T 'k32') +
        (T 'k33') +
        (T 'k34') -f $hintText)
    $desc.ForeColor = [System.Drawing.Color]::FromArgb(192, 57, 43)
    $desc.SetBounds(24, 52, 436, 92)
    $script:Dlg.Controls.Add($desc)

    $lbCur = New-Object System.Windows.Forms.Label
    $lbCur.AutoSize = $false
    $lbCur.Text = (T 'k35')
    $lbCur.ForeColor = [System.Drawing.Color]::FromArgb(70, 74, 80)
    $lbCur.SetBounds(24, 152, 436, 20)
    $script:Dlg.Controls.Add($lbCur)

    $script:DlgCurAuth = New-Object System.Windows.Forms.TextBox
    $script:DlgCurAuth.PasswordChar = [char]0x25CF
    $script:DlgCurAuth.ImeMode = [System.Windows.Forms.ImeMode]::Disable
    $script:DlgCurAuth.MaxLength = 128
    $script:DlgCurAuth.SetBounds(24, 174, 436, 26)
    $script:Dlg.Controls.Add($script:DlgCurAuth)

    $lb1 = New-Object System.Windows.Forms.Label
    $lb1.AutoSize = $false
    $lb1.Text = (T 'k36')
    $lb1.ForeColor = [System.Drawing.Color]::FromArgb(70, 74, 80)
    $lb1.SetBounds(24, 210, 436, 20)
    $script:Dlg.Controls.Add($lb1)

    $script:DlgPwd1 = New-Object System.Windows.Forms.TextBox
    $script:DlgPwd1.PasswordChar = [char]0x25CF
    $script:DlgPwd1.ImeMode = [System.Windows.Forms.ImeMode]::Disable
    $script:DlgPwd1.MaxLength = 128
    $script:DlgPwd1.SetBounds(24, 232, 436, 26)
    $script:Dlg.Controls.Add($script:DlgPwd1)

    $lb2 = New-Object System.Windows.Forms.Label
    $lb2.AutoSize = $false
    $lb2.Text = (T 'k37')
    $lb2.ForeColor = [System.Drawing.Color]::FromArgb(70, 74, 80)
    $lb2.SetBounds(24, 268, 436, 20)
    $script:Dlg.Controls.Add($lb2)

    $script:DlgPwd2 = New-Object System.Windows.Forms.TextBox
    $script:DlgPwd2.PasswordChar = [char]0x25CF
    $script:DlgPwd2.ImeMode = [System.Windows.Forms.ImeMode]::Disable
    $script:DlgPwd2.MaxLength = 128
    $script:DlgPwd2.SetBounds(24, 290, 436, 26)
    $script:Dlg.Controls.Add($script:DlgPwd2)

    $err = New-Object System.Windows.Forms.Label
    $err.AutoSize = $false
    $err.ForeColor = [System.Drawing.Color]::FromArgb(206, 55, 55)
    $err.SetBounds(24, 322, 436, 20)
    $err.Visible = $false
    $script:DlgErr = $err
    $script:Dlg.Controls.Add($err)

    $ok = New-Object System.Windows.Forms.Button
    $ok.Text = (T 'k38')
    $ok.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $ok.FlatAppearance.BorderSize = 0
    $ok.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 212)
    $ok.ForeColor = [System.Drawing.Color]::White
    $ok.Font = New-Object System.Drawing.Font($family, [float]10)
    $ok.SetBounds(240, 352, 136, 32)
    $script:Dlg.Controls.Add($ok)

    $cancel = New-Object System.Windows.Forms.Button
    $cancel.Text = (T 'k39')
    $cancel.Tag = 'dismiss'          
    $cancel.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $cancel.FlatAppearance.BorderSize = 0
    $cancel.BackColor = [System.Drawing.Color]::FromArgb(232, 233, 237)
    $cancel.ForeColor = [System.Drawing.Color]::FromArgb(40, 40, 44)
    $cancel.Font = New-Object System.Drawing.Font($family, [float]10)
    $cancel.SetBounds(384, 352, 96, 32)
    $script:Dlg.Controls.Add($cancel)

    $tip = New-Object System.Windows.Forms.Label
    $tip.AutoSize = $false
    $tip.Text = ''
    $tip.ForeColor = [System.Drawing.Color]::FromArgb(150, 154, 160)
    $tip.Font = New-Object System.Drawing.Font($family, [float]8.5)
    $tip.SetBounds(24, 398, 436, 36)
    $script:Dlg.Controls.Add($tip)

    $script:Dlg.AcceptButton = $ok
    $script:Dlg.CancelButton = $cancel
    $script:Dlg.Add_Shown({ $null = $script:DlgCurAuth.Focus() })
    if ($script:AuthLockedOut) { Set-AuthLockedUI -Dlg $script:Dlg -Tip $tip -Permanent:$script:AuthBanned }

    $ok.Add_Click({
            if (-not (Test-AuthCode -Code $script:DlgCurAuth.Text -Source $script:DlgStore)) {
                $script:DlgFails++
                if ($script:DlgFails -ge 3) {
                    
                    
                    $script:DlgFails = 0
                    $script:AuthLockedOut = $true
                    $script:DlgResult = 'toomany'   
                    Set-AuthBanned
                    $script:AuthBanned = $true
                    Set-AuthLockedUI -Dlg $script:Dlg -Tip $tip -Permanent
                    return
                }
                
                $script:DlgErr.Visible = $false
                $script:DlgCurAuth.Clear()
                $null = $script:DlgCurAuth.Focus()
                return
            }
            $check = Test-NewPasswordInput -First $script:DlgPwd1.Text -Second $script:DlgPwd2.Text `
                -KeyTooShort 'k42' -KeyNotAscii 'k43' -KeyMismatch 'k44'
            if ($check.Message.Length -gt 0) {
                Show-DialogError -Label $script:DlgErr -Message $check.Message
                if ($check.Field -eq 2) { $script:DlgPwd2.Clear(); $null = $script:DlgPwd2.Focus() }
                else { $null = $script:DlgPwd1.Focus() }
                return
            }
            try {
                $record = New-PasswordRecord -Password $a -Auth $script:DlgStore
                $null = Save-PasswordConfig -Record $record -Store $script:DlgStore
                $script:Config = $record
                $script:DlgResult = 'ok'
            }
            catch {
                $script:DlgErr.Text = (T 'k45') + $_.Exception.Message
                $script:DlgErr.Visible = $true
                return
            }
            $script:Dlg.DialogResult = [System.Windows.Forms.DialogResult]::OK
        })
    $cancel.Add_Click({
            if ($script:DlgResult -ne 'toomany') { $script:DlgResult = 'cancel' }
            $script:Dlg.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        })

    $script:DlgCurAuth.Add_TextChanged({ if ($script:DlgErr.Visible) { $script:DlgErr.Visible = $false } })
    $script:DlgPwd1.Add_TextChanged({ if ($script:DlgErr.Visible) { $script:DlgErr.Visible = $false } })
    $script:DlgPwd2.Add_TextChanged({ if ($script:DlgErr.Visible) { $script:DlgErr.Visible = $false } })

    Set-DialogDpi -Dlg $script:Dlg -Family $family -BasePt 9 -Items @(
        @{ Control = $head; Pt = $headPt; Style = [System.Drawing.FontStyle]::Bold },
        @{ Control = $desc; Pt = 9 },
        @{ Control = $ok; Pt = 10 },
        @{ Control = $cancel; Pt = 10 },
        @{ Control = $tip; Pt = 8.5 })

    $null = $script:Dlg.ShowDialog()
    try { $script:Dlg.Dispose() } catch { }
    $script:Dlg = $null
    $script:DlgCurAuth = $null
    $script:DlgPwd1 = $null
    $script:DlgPwd2 = $null
    $script:DlgErr = $null
    $script:DlgStore = $null
    return $script:DlgResult
}




function Stop-SingleInstance {
    
    try { if ($script:Mutex) { $script:Mutex.ReleaseMutex(); $script:Mutex.Dispose(); $script:Mutex = $null } } catch { }
}
if (-not $SelfTest) {
    

    
    $script:Mutex = New-Object System.Threading.Mutex($false, 'Local\CAScreenGuard.SingleInstance')
    $hasMutex = $false
    try { $hasMutex = $script:Mutex.WaitOne(0) }
    catch [System.Threading.AbandonedMutexException] { $hasMutex = $true }   
    catch { $hasMutex = $false }
    if (-not $hasMutex) {
        
        
        
        [System.Windows.Forms.MessageBox]::Show((T 'k46'), (T 'k66')) | Out-Null
        exit 0
    }

    
    $prev = Test-PreviousSession
    Remove-RunningFlag
    if ($prev) {
        if ($prev.crashLog) {
            [System.Windows.Forms.MessageBox]::Show(((T 'k61') -f $prev.crashLog), (T 'k60'), 'OK', 'Warning') | Out-Null
        }
        else {
            [System.Windows.Forms.MessageBox]::Show((T 'k62'), (T 'k60'), 'OK', 'Warning') | Out-Null
        }
    }

    
    
    $script:AutoReset = [bool]$ResetPassword
    $script:Config = Read-PasswordConfig
    $integrity = Test-ConfigIntegrity -ConfigRecord $script:Config -RawText $script:ConfigRaw

    if ($integrity -ne 'ok') {
        if ($integrity -eq 'fresh') {
            [System.Windows.Forms.MessageBox]::Show(
                (T 'k47'),
                'CAScreenGuard', 'OK', 'Information') | Out-Null
            Stop-SingleInstance
            exit 0
        }
        elseif ($integrity -eq 'unprovable') {
            [System.Windows.Forms.MessageBox]::Show(
                (T 'k48'),
                (T 'k49'), 'OK', 'Warning') | Out-Null
            Stop-SingleInstance
            exit 0
        }
        else {
            
            $outcome = Show-RebuildDialog
            if ($outcome -ne 'ok') {
                $note = (T 'k50')
                if ($outcome -eq 'toomany') { $note = (T 'k51') }
                [System.Windows.Forms.MessageBox]::Show(
                    (T 'k52') + $note,
                    (T 'k53'), 'OK', 'Warning') | Out-Null
                Stop-SingleInstance
                exit 0
            }
        }
    }
}
else {
    
    $script:Config = New-PasswordRecord -Password 'selftest-dummy-pw'
}




$family = $script:UiFamily
$cardW = 580

$cardH = 304

$script:Form = New-Object System.Windows.Forms.Form
$script:Form.Text = 'CAScreenGuard'
$script:Form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
$script:Form.StartPosition = [System.Windows.Forms.FormStartPosition]::Manual
$script:Form.Bounds = [System.Windows.Forms.SystemInformation]::VirtualScreen
$script:Form.TopMost = $true
$script:Form.ShowInTaskbar = $false
$script:Form.KeyPreview = $true
$script:Form.BackColor = [System.Drawing.Color]::Black
$script:Form.ImeMode = [System.Windows.Forms.ImeMode]::Disable


try {
    $setStyle = $script:Form.GetType().GetMethod('SetStyle', [System.Reflection.BindingFlags]'Instance,NonPublic')
    $bufferStyles = [System.Windows.Forms.ControlStyles]::UserPaint -bor [System.Windows.Forms.ControlStyles]::AllPaintingInWmPaint -bor [System.Windows.Forms.ControlStyles]::DoubleBuffer -bor [System.Windows.Forms.ControlStyles]::OptimizedDoubleBuffer
    $null = $setStyle.Invoke($script:Form, @($bufferStyles, $true))
} catch { }

$card = New-Object System.Windows.Forms.Panel
$card.Size = New-Object System.Drawing.Size($cardW, $cardH)
$card.BackColor = [System.Drawing.Color]::FromArgb(13, 13, 15)
$script:Form.Controls.Add($card)







$titleText = (T 'k54')
$titleFont = New-Object System.Drawing.Font($family, [float]22, [System.Drawing.FontStyle]::Bold)

$titleW = [int]([System.Windows.Forms.TextRenderer]::MeasureText($titleText, $titleFont).Width / $script:Scale)
$titleY = 34
$handSize = 34
$handGap = 4
$groupX = [int](($cardW - ($handSize + $handGap + $titleW)) / 2)

$title = New-Object System.Windows.Forms.Label
$title.AutoSize = $false
$title.Text = $titleText
$title.Font = $titleFont
$title.ForeColor = [System.Drawing.Color]::FromArgb(242, 242, 244)
$title.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
$title.SetBounds($groupX + $handSize + $handGap, $titleY, $titleW + 8, 44)
$card.Controls.Add($title)


$handMark = New-Object System.Windows.Forms.Panel
$handMark.SetBounds($groupX, $titleY + [int]((44 - $handSize) / 2), $handSize, $handSize)
$handMark.BackColor = [System.Drawing.Color]::FromArgb(13, 13, 15)
$handMark.Add_Paint({
        param($sender, $e)
        try {
            
            
            
            $e.Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
            $e.Graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias
            $f = [float]$sender.Width
            $font = New-Object System.Drawing.Font('Segoe UI Symbol', [float]($f * 1.02), [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
            $fmt = New-Object System.Drawing.StringFormat
            $fmt.Alignment = [System.Drawing.StringAlignment]::Center
            $fmt.LineAlignment = [System.Drawing.StringAlignment]::Center
            $brush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(242, 242, 244))
            $e.Graphics.DrawString([string][char]0x270B, $font, $brush, (New-Object System.Drawing.RectangleF(0, 0, $f, $f)), $fmt)
            $brush.Dispose(); $fmt.Dispose(); $font.Dispose()
        } catch { }
    })
$card.Controls.Add($handMark)

$subtitle = New-Object System.Windows.Forms.Label
$subtitle.AutoSize = $false
$subtitle.Text = (T 'k55')
$subtitle.Font = New-Object System.Drawing.Font($family, [float]10.5)
$subtitle.ForeColor = [System.Drawing.Color]::FromArgb(152, 158, 166)
$subtitle.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$subtitle.SetBounds(0, 82, $cardW, 26)
$card.Controls.Add($subtitle)

$boxW = 400
$boxH = 52
$box = New-Object System.Windows.Forms.Panel
$box.Size = New-Object System.Drawing.Size($boxW, $boxH)
$box.Location = New-Object System.Drawing.Point([int](($cardW - $boxW) / 2), 130)
$box.BackColor = [System.Drawing.Color]::FromArgb(26, 26, 30)
$script:BoxPanel = $box          
$card.Controls.Add($box)

$script:Txt = New-Object System.Windows.Forms.TextBox
$script:Txt.BorderStyle = [System.Windows.Forms.BorderStyle]::None
$script:Txt.Font = New-Object System.Drawing.Font($family, [float]17)
$script:Txt.BackColor = [System.Drawing.Color]::FromArgb(26, 26, 30)
$script:Txt.ForeColor = [System.Drawing.Color]::White
$script:Txt.TextAlign = [System.Windows.Forms.HorizontalAlignment]::Center
$script:Txt.PasswordChar = [char]0x25CF
$script:Txt.ImeMode = [System.Windows.Forms.ImeMode]::Disable
$script:Txt.MaxLength = 128
$script:Txt.SetBounds(12, 9, $boxW - 24, 26)
$box.Controls.Add($script:Txt)

$script:TxtError = New-Object System.Windows.Forms.Label
$script:TxtError.AutoSize = $false
$script:TxtError.Font = New-Object System.Drawing.Font($family, [float]10)
$script:TxtError.ForeColor = [System.Drawing.Color]::FromArgb(255, 110, 110)
$script:TxtError.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$script:TxtError.SetBounds(0, 194, $cardW, 24)
$script:TxtError.Visible = $false
$card.Controls.Add($script:TxtError)

$footer1 = New-Object System.Windows.Forms.Label
$footer1.AutoSize = $false
$footer1.Text = (T 'k56')

$script:FooterPt = 9.5
if ($script:Lang -eq 'en') { $script:FooterPt = 8.5 }
$footer1.Font = New-Object System.Drawing.Font($family, [float]$script:FooterPt)
$footer1.ForeColor = [System.Drawing.Color]::FromArgb(128, 134, 142)
$footer1.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$footer1.SetBounds(0, 230, $cardW, 22)
$script:Footer1 = $footer1          
$card.Controls.Add($footer1)

$footer2 = New-Object System.Windows.Forms.Label
$footer2.AutoSize = $false
$footer2.Text = (T 'k57')
$footer2.Font = New-Object System.Drawing.Font($family, [float]9)
$footer2.ForeColor = [System.Drawing.Color]::FromArgb(86, 92, 100)
$footer2.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter


$script:LockNotice = New-Object System.Windows.Forms.Label
$script:LockNotice.AutoSize = $false
$script:LockNotice.Font = New-Object System.Drawing.Font($family, [float]10)
$script:LockNotice.ForeColor = [System.Drawing.Color]::FromArgb(255, 96, 96)
$script:LockNotice.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$script:LockNotice.Text = (T 'k63') + "`r`n" + (T 'k64')


$script:LockNotice.SetBounds(0, 228, $cardW, 54)
$script:LockNotice.Visible = $false
$card.Controls.Add($script:LockNotice)
$footer2.SetBounds(0, 254, $cardW, 22)
$script:Footer2 = $footer2
$card.Controls.Add($footer2)




$script:ClockTime = New-Object System.Windows.Forms.Label
$script:ClockTime.AutoSize = $false
$script:ClockTime.BackColor = [System.Drawing.Color]::Transparent
$script:ClockTime.ForeColor = [System.Drawing.Color]::FromArgb(238, 238, 242)
$script:ClockTime.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$script:Form.Controls.Add($script:ClockTime)

$script:ClockDate = New-Object System.Windows.Forms.Label
$script:ClockDate.AutoSize = $false
$script:ClockDate.BackColor = [System.Drawing.Color]::Transparent
$script:ClockDate.ForeColor = [System.Drawing.Color]::FromArgb(150, 156, 164)
$script:ClockDate.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$script:Form.Controls.Add($script:ClockDate)

function Update-NetInfo {
    
    
    try {
        $wifi = $false
        $wired = $false
        foreach ($ni in [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces()) {
            if ($ni.OperationalStatus -ne [System.Net.NetworkInformation.OperationalStatus]::Up) { continue }
            $t = $ni.NetworkInterfaceType
            if ($t -eq [System.Net.NetworkInformation.NetworkInterfaceType]::Loopback) { continue }
            if ($t -eq [System.Net.NetworkInformation.NetworkInterfaceType]::Tunnel) { continue }
            if ($t -eq [System.Net.NetworkInformation.NetworkInterfaceType]::Wireless80211) { $wifi = $true }
            else { $wired = $true }
        }
        $kind = 'none'
        if ($wifi) { $kind = 'wifi' }
        elseif ($wired) { $kind = 'eth' }
        
        
        if ($kind -eq 'wifi') {
            $lastProbe = $script:LastWifiProbe
            if ($null -eq $lastProbe) { $lastProbe = [datetime]::MinValue }
            $sigNow = Get-Date
            if ((($sigNow - $lastProbe).TotalSeconds -ge 30) -or ($null -eq $script:WifiSignal) -or ($script:WifiSignal -lt 0)) {
                $script:LastWifiProbe = $sigNow
                try {
                    $netshPath = Join-Path $env:SystemRoot 'System32\netsh.exe'
                    $netshOut = [ScreenLockNative]::RunHidden($netshPath, 'wlan show interfaces')
                    $sigMatch = [regex]::Match([string]$netshOut, '(\d{1,3})\s*%')
                    if ($sigMatch.Success) {
                        $script:WifiSignal = [int]$sigMatch.Groups[1].Value
                        try { $script:Form.Invalidate() } catch { }
                    }
                } catch { }
            }
        }
        else {
            $script:WifiSignal = -1
        }
        if ($script:NetKind -ne $kind) {
            $script:NetKind = $kind
            try { $script:Form.Invalidate() } catch { }
        }
    } catch { }
}

function Update-AgentState {
    
    
    
    
    $list = New-Object System.Collections.ArrayList
    try {
        $dir = Join-Path $env:LOCALAPPDATA 'CAScreenGuard'
        $files = New-Object System.Collections.ArrayList
        $agDir = Join-Path $dir 'agents'
        if (Test-Path -LiteralPath $agDir) {
            foreach ($fi in @(Get-ChildItem -LiteralPath $agDir -Filter '*.json' -File -ErrorAction SilentlyContinue)) {
                [void]$files.Add($fi.FullName)
            }
        }
        if ($files.Count -eq 0) {
            $legacy = Join-Path $dir 'agent-state.json'
            if (Test-Path -LiteralPath $legacy) { [void]$files.Add($legacy) }
        }
        $lock = $script:LockStartedAt
        if ($null -eq $lock) { $lock = [datetime]::MinValue }
        $now = Get-Date
        foreach ($p in $files) {
            try {
                $o = (Get-Content -LiteralPath $p -Raw -ErrorAction Stop) | ConvertFrom-Json -ErrorAction Stop
                $state = [string]$o.state
                if (($state -ne 'working') -and ($state -ne 'waiting')) { continue }
                $since = [datetime]::MinValue
                try {
                    $since = [datetime]::Parse([string]$o.since, [System.Globalization.CultureInfo]::InvariantCulture).ToLocalTime()
                } catch { continue }
                $age = ($now - $since).TotalSeconds
                if (($age -lt 0) -or ($age -gt 600)) { continue }
                if (($state -eq 'waiting') -and ($since -lt $lock)) { continue }
                
                $prec = 'exact'
                if ([string]$o.precision -eq 'inferred') { $prec = 'inferred' }
                [void]$list.Add([pscustomobject]@{
                    State = $state; Reason = [string]$o.reason; Since = $since; Age = $age
                    Source = [string]$o.source; Precision = $prec
                })
            } catch { }
        }
    } catch { }
    $script:AgentSessions = $list
}

function Update-PowerInfo {
    
    
    try {
        Update-NetInfo
        Update-AgentState
        $ps = [System.Windows.Forms.SystemInformation]::PowerStatus
        if ($null -eq $ps) { return }
        $flags = $ps.BatteryChargeStatus
        if (($flags -band [System.Windows.Forms.BatteryChargeStatus]::NoSystemBattery) -ne 0) {
            if ($null -ne $script:PowerInfo) {
                $script:PowerInfo = $null
                try { $script:Form.Invalidate() } catch { }
            }
            return
        }
        $percent = -1
        $raw = [double]$ps.BatteryLifePercent
        if (($raw -ge 0) -and ($raw -le 1)) { $percent = [int][math]::Round($raw * 100) }
        $charging = (($flags -band [System.Windows.Forms.BatteryChargeStatus]::Charging) -ne 0)
        $changed = $true
        if ($null -ne $script:PowerInfo) {
            $changed = (($script:PowerInfo.Percent -ne $percent) -or ($script:PowerInfo.Charging -ne $charging))
        }
        if ($changed) {
            $script:PowerInfo = [pscustomobject]@{ Percent = $percent; Charging = $charging }
            try { $script:Form.Invalidate() } catch { }
        }
    } catch { }
}

function Update-Clock {
    
    try {
        $now = Get-Date
        $timeText = $now.ToString('HH:mm')
        if ($script:ClockTime.Text -ne $timeText) { $script:ClockTime.Text = $timeText }
        if ($script:Lang -eq 'zh') {
            $dateText = $now.ToString('M月d日 dddd', [System.Globalization.CultureInfo]::GetCultureInfo('zh-CN'))
        }
        else {
            $dateText = $now.ToString('dddd, MMM d', [System.Globalization.CultureInfo]::GetCultureInfo('en-US'))
        }
        if ($script:ClockDate.Text -ne $dateText) { $script:ClockDate.Text = $dateText }
        
        if (((Get-Date) - $script:LastPowerRead).TotalSeconds -ge 10) {
            $script:LastPowerRead = Get-Date
            Update-PowerInfo
        }
    } catch { }
}
Update-Clock


$primary = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds





if ($script:Scale -gt 1.01) {
    $script:Form.Scale((New-Object System.Drawing.SizeF([float]$script:Scale, [float]$script:Scale)))
    $script:Form.Bounds = [System.Windows.Forms.SystemInformation]::VirtualScreen
    $title.Font = New-Object System.Drawing.Font($family, [float]22, [System.Drawing.FontStyle]::Bold)
    $subtitle.Font = New-Object System.Drawing.Font($family, [float]10.5)
    $script:Txt.Font = New-Object System.Drawing.Font($family, [float]17)
    $script:TxtError.Font = New-Object System.Drawing.Font($family, [float]10)
    $footer1.Font = New-Object System.Drawing.Font($family, [float]$script:FooterPt)
    $footer2.Font = New-Object System.Drawing.Font($family, [float]9)
    $script:LockNotice.Font = New-Object System.Drawing.Font($family, [float]10)
}







$ox = $primary.X - $script:Form.Bounds.X
$oy = $primary.Y - $script:Form.Bounds.Y

$fontTime = New-Object System.Drawing.Font($family, [float]74, [System.Drawing.FontStyle]::Bold)
$fontDate = New-Object System.Drawing.Font($family, [float]17, [System.Drawing.FontStyle]::Bold)
$script:ClockTime.Font = $fontTime
$script:ClockDate.Font = $fontDate
$script:ClockTime.ForeColor = [System.Drawing.Color]::FromArgb(245, 246, 248)
$script:ClockDate.ForeColor = [System.Drawing.Color]::FromArgb(226, 230, 236)

$clockW = [int]($primary.Width * 0.8)
$clockX = [int]($ox + ($primary.Width - $clockW) / 2)
$timeH = [System.Windows.Forms.TextRenderer]::MeasureText($script:ClockTime.Text, $fontTime).Height
$dateH = [System.Windows.Forms.TextRenderer]::MeasureText($script:ClockDate.Text, $fontDate).Height


$timeLeadDip = 0.257 * 74 * 96.0 / 72.0
$dateLeadDip = 0.257 * 17 * 96.0 / 72.0
$timeTop = [int]($oy + (162 - $timeLeadDip) * $script:Scale)
$dateTop = [int]($oy + (162 + 71 + 32 - $dateLeadDip) * $script:Scale)
$script:ClockTime.SetBounds($clockX, $timeTop, $clockW, $timeH)
$script:ClockDate.SetBounds($clockX, $dateTop, $clockW, $dateH)


$cardTop = [int]($oy + ($primary.Height - $card.Height) / 2)
$minTop = $dateTop + $dateH + [int](28 * $script:Scale)
if ($cardTop -lt $minTop) { $cardTop = $minTop }
$maxTop = [int]($oy + $primary.Height - $card.Height - 16 * $script:Scale)
if ($cardTop -gt $maxTop -and $maxTop -gt $minTop) { $cardTop = $maxTop }
$card.Left = [int]($ox + ($primary.Width - $card.Width) / 2)
$card.Top = $cardTop


$cardR = [int](18 * $script:Scale)
if ($cardR -lt 12) { $cardR = 12 }
$cardPath = New-RoundedPath 0 0 $card.Width $card.Height $cardR
$card.Region = New-Object System.Drawing.Region($cardPath)
$cardPath.Dispose()
$boxPath = New-RoundedPath 0 0 $box.Width $box.Height ([int]($box.Height / 2))
$box.Region = New-Object System.Drawing.Region($boxPath)
$boxPath.Dispose()





$edgeX = [int](48 * $script:Scale)          
$edgeY = [int](40 * $script:Scale)          
$barH = [int](40 * $script:Scale)           
$script:MarkSize = [int](30 * $script:Scale)
$script:MarkGap = [int](13 * $script:Scale)


try {
    $wmBytes = [Convert]::FromBase64String($script:WordmarkB64)
    $script:WordmarkImg = [System.Drawing.Image]::FromStream((New-Object System.IO.MemoryStream(,$wmBytes)))
} catch { $script:WordmarkImg = $null }
$script:WmH = [int]($barH * 0.42)
$script:WmW = 0
if (($null -ne $script:WordmarkImg) -and ($script:WordmarkImg.Height -gt 0)) {
    $script:WmW = [int]($script:WmH * ($script:WordmarkImg.Width / $script:WordmarkImg.Height))
}


$script:PowerPt = 11.5
$script:PowerIconH = [int](15 * $script:Scale)
$script:PowerGap = [int](9 * $script:Scale)
$powFontTmp = New-Object System.Drawing.Font($script:UiFamily, [float]$script:PowerPt)
$script:PowerTextW = [int]([System.Windows.Forms.TextRenderer]::MeasureText('100%', $powFontTmp).Width)
$powFontTmp.Dispose()

$script:EdgeX = $edgeX
$script:EdgeY = $edgeY
$script:BarH = $barH

$script:Form.Add_Paint({
        param($sender, $e)
        try {
            $g = $e.Graphics
            $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
            $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
            $ink = [System.Drawing.Color]::FromArgb(236, 240, 245)
            $bottom = [float]($sender.ClientSize.Height - $script:EdgeY - $script:BarH)

            
            $f = [float]$script:MarkSize
            $top = $bottom + ($script:BarH - $f) / 2
            $side = $f * 0.62
            $radius = $f * 0.16
            
            
            $markX = [float]($script:EdgeX)
            $layers = @(
                @{ ox = $f * 0.40; oy = $f * 0.40; color = [System.Drawing.Color]::FromArgb(47, 168, 248) },
                @{ ox = $f * 0.60; oy = $f * 0.60; color = [System.Drawing.Color]::FromArgb(124, 77, 255) })
            foreach ($layer in $layers) {
                $g.ResetTransform()
                $g.TranslateTransform(($markX + $layer.ox), ($top + $layer.oy))
                $g.RotateTransform(-10)
                $path = New-RoundedPath (-$side / 2) (-$side / 2) $side $side $radius
                $brush = New-Object System.Drawing.SolidBrush $layer.color
                $g.FillPath($brush, $path)
                $brush.Dispose(); $path.Dispose()
            }
            $g.ResetTransform()
            if (($null -ne $script:WordmarkImg) -and ($script:WmW -gt 0)) {
                $rect = New-Object System.Drawing.RectangleF(
                    [float]($script:EdgeX + $script:MarkSize + $script:MarkGap),
                    [float]($bottom + ($script:BarH - $script:WmH) / 2),
                    [float]$script:WmW, [float]$script:WmH)
                $g.DrawImage($script:WordmarkImg, $rect)
            }

            
            $info = $script:PowerInfo
            if ($null -ne $info) {
                $h = [float]$script:PowerIconH
                $bw = [float]($h * 1.9)               
                $nub = [float]($h * 0.16)
                $bodyW = [float]($bw - $nub)
                $r = [float]($h * 0.24)
                $penW = [float][math]::Max(1.2, $script:Scale * 0.9)
                
                
                $padX = [float](14 * $script:Scale)
                $padY = [float](6 * $script:Scale)
                
                $netW = [float]($h * 1.15)
                $netGap = [float]($script:PowerGap)
                $pillW = [float]($netW + $netGap + $bw + $script:PowerGap + $script:PowerTextW + $padX * 2)
                $pillH = [float]($h + $padY * 2)
                $pillX = [float]($sender.ClientSize.Width - $script:EdgeX - $pillW)
                $pillY = [float]($bottom + ($script:BarH - $pillH) / 2)
                
                $pillR = [float][math]::Min($pillH / 2, 10 * $script:Scale)
                $pill = New-RoundedPath $pillX $pillY $pillW $pillH $pillR
                $plate = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(44, 24, 26, 30))
                $g.FillPath($plate, $pill)
                $plate.Dispose()
                $ring = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(40, 236, 240, 245)), ([float][math]::Max(1, $script:Scale * 0.8))
                $g.DrawPath($ring, $pill)
                $ring.Dispose()
                $pill.Dispose()
                $x = [float]($pillX + $padX)
                $y = [float]($pillY + $padY)
                
                $nk = $script:NetKind
                if ([string]::IsNullOrEmpty($nk)) { $nk = 'none' }
                $ncx = [float]($x + $netW / 2)
                $ncy = [float]($y + $h * 0.68)
                $npen = New-Object System.Drawing.Pen $ink, ([float][math]::Max(1.8, $h * 0.13))
                if ($nk -eq 'wifi') {
                    $npen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
                    $npen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
                    
                    
                    $wifiLvl = 3
                    if (($script:WifiSignal -ge 0) -and ($script:WifiSignal -lt 25)) { $wifiLvl = 1 }
                    elseif (($script:WifiSignal -ge 0) -and ($script:WifiSignal -lt 55)) { $wifiLvl = 2 }
                    for ($wi = 0; $wi -lt 3; $wi++) {
                        $arcR = [float]($h * (0.21 + 0.17 * $wi))
                        $arcRect = New-Object System.Drawing.RectangleF(($ncx - $arcR), ($ncy - $arcR), ($arcR * 2), ($arcR * 2))
                        if ($wi -lt $wifiLvl) {
                            $g.DrawArc($npen, $arcRect, 220, 100)
                        }
                        else {
                            
                            $dimPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(72, $ink)), $npen.Width
                            $dimPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
                            $dimPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
                            $g.DrawArc($dimPen, $arcRect, 220, 100)
                            $dimPen.Dispose()
                        }
                    }
                    $g.FillEllipse((New-Object System.Drawing.SolidBrush $ink), ($ncx - $h * 0.06), ($ncy - $h * 0.06), ($h * 0.12), ($h * 0.12))
                }
                else {
                    
                    
                    
                    
                    $gcy = [float]($y + $h * 0.5)
                    $gr = [float]($h * 0.38)
                    $grRect = New-Object System.Drawing.RectangleF(($ncx - $gr), ($gcy - $gr), ($gr * 2), ($gr * 2))
                    $g.DrawEllipse($npen, $grRect)
                    $g.DrawEllipse($npen, ($ncx - $gr * 0.42), ($gcy - $gr), ($gr * 0.84), ($gr * 2))
                    $g.DrawLine($npen, ($ncx - $gr), $gcy, ($ncx + $gr), $gcy)
                    if ($nk -ne 'eth') {
                        $g.DrawLine($npen, ($ncx - $gr * 0.88), ($gcy + $gr * 0.88), ($ncx + $gr * 0.88), ($gcy - $gr * 0.88))
                    }
                }
                $npen.Dispose()
                $x += $netW + $netGap
                $pen = New-Object System.Drawing.Pen $ink, $penW
                $body = New-RoundedPath $x $y $bodyW $h $r
                $g.DrawPath($pen, $body)
                $body.Dispose(); $pen.Dispose()
                $nb = New-RoundedPath ($x + $bodyW - 1) ($y + ($h - $h * 0.44) / 2) ($nub + 1) ($h * 0.44) ([float]($h * 0.12))
                $g.FillPath((New-Object System.Drawing.SolidBrush $ink), $nb)
                $nb.Dispose()
                if ($info.Percent -ge 0) {
                    $innerW = [float]($bodyW - $penW * 3)
                    $innerH = [float]($h - $penW * 3)
                    $fillW = [float]($innerW * ($info.Percent / 100.0))
                    if ($fillW -ge 1) {
                        $fc = $ink
                        if ($info.Percent -le 15) { $fc = [System.Drawing.Color]::FromArgb(240, 96, 96) }
                        $fill = New-RoundedPath ($x + $penW * 1.5) ($y + $penW * 1.5) $fillW $innerH ([float][math]::Max(1.0, $innerH * 0.25))
                        $g.FillPath((New-Object System.Drawing.SolidBrush $fc), $fill)
                        $fill.Dispose()
                    }
                }
                if ($info.Charging) {
                    
                    
                    $bx = [float]($x + $bodyW / 2)
                    $by = [float]($y + $h / 2)
                    $k = [float]($h * 0.34)
                    $boltColor = [System.Drawing.Color]::FromArgb(255, 214, 102)
                    if ($info.Percent -ge 0) { $boltColor = [System.Drawing.Color]::FromArgb(18, 20, 24) }
                    $bolt = [System.Drawing.PointF[]]@(
                        [System.Drawing.PointF]::new(($bx + $k * 0.10), ($by - $k)),
                        [System.Drawing.PointF]::new(($bx - $k * 0.42), ($by + $k * 0.08)),
                        [System.Drawing.PointF]::new(($bx - $k * 0.02), ($by + $k * 0.08)),
                        [System.Drawing.PointF]::new(($bx - $k * 0.14), ($by + $k)),
                        [System.Drawing.PointF]::new(($bx + $k * 0.44), ($by - $k * 0.10)),
                        [System.Drawing.PointF]::new(($bx + $k * 0.02), ($by - $k * 0.10)))
                    $g.FillPolygon((New-Object System.Drawing.SolidBrush $boltColor), $bolt)
                }
                if ($info.Percent -ge 0) {
                    $font = New-Object System.Drawing.Font($script:UiFamily, [float]$script:PowerPt)
                    $fmt = New-Object System.Drawing.StringFormat
                    $fmt.Alignment = [System.Drawing.StringAlignment]::Far
                    $fmt.LineAlignment = [System.Drawing.StringAlignment]::Center
                    
                    $txtRect = New-Object System.Drawing.RectangleF(
                        [float]($pillX + $pillW - $padX - $script:PowerTextW),
                        [float]$pillY, [float]$script:PowerTextW, [float]$pillH)
                    $g.DrawString(("$($info.Percent)%"), $font, (New-Object System.Drawing.SolidBrush $ink), $txtRect, $fmt)
                    $fmt.Dispose(); $font.Dispose()
                }
            }
        } catch { }
    })




$script:Form.Add_Paint({
        param($sender, $e)
        try {
            $sessions = $script:AgentSessions
            if (($null -eq $sessions) -or ($sessions.Count -eq 0)) { return }
            $g = $e.Graphics
            $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
            $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias

            $isZh = ($script:Lang -eq 'zh')
            
            
            $exact = @($sessions | Where-Object { $_.Precision -eq 'exact' })
            $inferred = @($sessions | Where-Object { $_.Precision -ne 'exact' })
            $asking = @($exact | Where-Object { $_.State -eq 'waiting' -and $_.Reason -eq 'question' })
            $working = @($exact | Where-Object { $_.State -eq 'working' })
            $finished = @($exact | Where-Object { $_.State -eq 'waiting' -and $_.Reason -ne 'question' })
            $n = $sessions.Count

            $tone = 'normal'
            if ($asking.Count -gt 0) {
                $tone = 'ask'
                $picked = ($asking | Sort-Object Age -Descending | Select-Object -First 1)
            }
            elseif ($working.Count -gt 0) {
                $picked = ($working | Sort-Object Age -Descending | Select-Object -First 1)
            }
            elseif ($finished.Count -gt 0) {
                $tone = 'done'
                $picked = ($finished | Sort-Object Since -Descending | Select-Object -First 1)
            }
            elseif ($inferred.Count -gt 0) {
                $tone = 'quiet'
                $picked = ($inferred | Sort-Object Since -Descending | Select-Object -First 1)
            }
            else { return }

            $mins = [int][math]::Floor($picked.Age / 60)
            $ago = ''
            if ($mins -lt 1) { $ago = $(if ($isZh) { '刚刚' } else { 'just now' }) }
            elseif ($isZh) { $ago = ($mins.ToString() + ' 分钟') }
            else { $ago = ($mins.ToString() + ' min') }

            
            $who = [string]$picked.Source
            if ([string]::IsNullOrEmpty($who)) { $who = 'Agent' }
            elseif ($who -eq 'dsh-plugin') { $who = 'DSH' }
            elseif ($who -eq 'claude-code') { $who = 'Claude' }
            elseif ($who -eq 'codex') { $who = 'Codex' }

            $many = ($n -gt 1)
            if ($tone -eq 'ask') {
                $txt = $(if ($isZh) { $(if ($many) { "$who 等你回答 · $n 个对话" } else { "$who 等你回答" }) + ' · ' + $ago }
                         else { $(if ($many) { "$who needs you · $n chats" } else { "$who needs you" }) + ' · ' + $ago })
            }
            elseif ($tone -eq 'quiet') {
                
                $txt = $(if ($isZh) { "$who 最后活动 · " + $ago + '前' } else { "$who last active · " + $ago + ' ago' })
            }
            elseif ($tone -eq 'done') {
                $txt = $(if ($isZh) { $(if ($many) { "$who 已完成 · $n 个对话" } else { "$who 已完成" }) + ' · ' + $ago + '前' }
                         else { $(if ($many) { "$who finished · $n chats" } else { "$who finished" }) + ' · ' + $ago + ' ago' })
            }
            else {
                $txt = $(if ($isZh) { $(if ($many) { "$who 正在工作 · $n 个对话" } else { "$who 正在工作" }) + ' · 已 ' + $ago }
                         else { $(if ($many) { "$who working · $n chats" } else { "$who working" }) + ' · ' + $ago })
            }
            $font = New-Object System.Drawing.Font($script:UiFamily, [float]$script:PowerPt)
            $sz = $g.MeasureString($txt, $font)
            $dot = [float](9 * $script:Scale)
            $padX = [float](14 * $script:Scale)
            $padY = [float](7 * $script:Scale)
            $gap = [float](8 * $script:Scale)
            $chipH = [float]($sz.Height + $padY * 2)
            $chipW = [float]($padX * 2 + $dot + $gap + $sz.Width)
            $chipX = [float]$script:EdgeX
            $chipY = [float]$script:EdgeY

            $plateColor = [System.Drawing.Color]::FromArgb(44, 24, 26, 30)
            $ink = [System.Drawing.Color]::FromArgb(236, 240, 245)
            $dotColor = [System.Drawing.Color]::FromArgb(120, 220, 150)
            if ($tone -eq 'ask') {
                $plateColor = [System.Drawing.Color]::FromArgb(96, 122, 86, 26)
                $dotColor = [System.Drawing.Color]::FromArgb(255, 196, 92)
                $ink = [System.Drawing.Color]::FromArgb(255, 226, 168)
            }
            elseif ($tone -eq 'done') {
                $dotColor = [System.Drawing.Color]::FromArgb(130, 138, 148)
                $ink = [System.Drawing.Color]::FromArgb(168, 176, 186)
            }

            $chipR = [float][math]::Min($chipH / 2, 10 * $script:Scale)
            $path = New-RoundedPath $chipX $chipY $chipW $chipH $chipR
            $plate = New-Object System.Drawing.SolidBrush $plateColor
            $g.FillPath($plate, $path)
            $plate.Dispose()
            $ring = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(38, 236, 240, 245)), ([float][math]::Max(1, $script:Scale * 0.8))
            $g.DrawPath($ring, $path)
            $ring.Dispose()
            $path.Dispose()

            $dr = [float]($dot / 2)
            $dcx = [float]($chipX + $padX + $dr)
            $dcy = [float]($chipY + $chipH / 2)
            $db = New-Object System.Drawing.SolidBrush $dotColor
            $g.FillEllipse($db, ($dcx - $dr), ($dcy - $dr), $dot, $dot)
            $db.Dispose()

            $tb = New-Object System.Drawing.SolidBrush $ink
            $g.DrawString($txt, $font, $tb, [float]($chipX + $padX + $dot + $gap), [float]($chipY + $padY - 1))
            $tb.Dispose(); $font.Dispose()
        } catch { }
    })

$script:LockStartedAt = Get-Date
$script:LastPowerRead = [datetime]::MinValue
$script:PowerInfo = $null
Update-PowerInfo



$box.Add_Paint({
        param($sender, $e)
        try {
            $color = $null
            if ($script:BoxState -eq 'error') { $color = [System.Drawing.Color]::FromArgb(224, 75, 74) }
            elseif (($script:BoxState -eq 'normal') -and $script:Txt.Focused) { $color = [System.Drawing.Color]::FromArgb(47, 168, 248) }
            if ($null -eq $color) { return }
            $pen = New-Object System.Drawing.Pen($color, [float]1.5)
            $path = New-RoundedPath 1 1 ($sender.Width - 3) ($sender.Height - 3) ([int](($sender.Height - 3) / 2))
            $e.Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
            $e.Graphics.DrawPath($pen, $path)
            $pen.Dispose()
            $path.Dispose()
        } catch { }
    })
$script:Txt.Add_GotFocus({ try { $script:BoxPanel.Invalidate() } catch { } })
$script:Txt.Add_LostFocus({ try { $script:BoxPanel.Invalidate() } catch { } })


$script:Form.Add_Shown({
        try { [ScreenLockNative]::DisableIme($script:Txt.Handle) } catch { }
        if ($script:Txt.Enabled) { $null = $script:Txt.Focus() }
    })

$script:Form.Add_Activated({
        if ($script:Txt.Enabled) { $null = $script:Txt.Focus() }
    })

$script:Form.Add_FormClosing({
        param($sender, $e)
        if (-not $script:AllowClose) { $e.Cancel = $true }
    })

$script:Form.Add_KeyDown({
        param($sender, $e)
        
        if ($e.Alt -and ($e.KeyCode -eq [System.Windows.Forms.Keys]::F4)) {
            $e.SuppressKeyPress = $true
            return
        }
        
        if ($e.Control -and $e.Alt -and $e.Shift -and ($e.KeyCode -eq [System.Windows.Forms.Keys]::E)) {
            $e.SuppressKeyPress = $true
            Invoke-ChangePasswordFlow
            return
        }
    })


$script:Form.Add_KeyPress({
        param($sender, $e)
        if ($script:Txt.Enabled -and -not $script:Txt.Focused -and $e.KeyChar -and ([int]$e.KeyChar -ge 32)) {
            $script:Txt.AppendText([string]$e.KeyChar)
            $e.Handled = $true
        }
    })

$script:Txt.Add_KeyDown({
        param($sender, $e)
        $code = $e.KeyCode

        if ($e.Control -and (($code -eq [System.Windows.Forms.Keys]::Back) -or ($code -eq [System.Windows.Forms.Keys]::U))) {
            
            $e.SuppressKeyPress = $true
            $sender.Clear()
            Hide-ErrorMsg
            return
        }
        if ($code -eq [System.Windows.Forms.Keys]::Escape) {
            
            $e.SuppressKeyPress = $true
            Invoke-GoDark
            return
        }
        if ($code -eq [System.Windows.Forms.Keys]::Enter) {
            $e.SuppressKeyPress = $true
            Invoke-SubmitAttempt
            return
        }
    })

$script:Txt.Add_TextChanged({
        if ($script:CooldownActive) { return }
        Hide-ErrorMsg
    })


$script:Timer = New-Object System.Windows.Forms.Timer
$script:Timer.Interval = 250
if ($SelfTest) {
    $script:Timer.Interval = 500
    $script:Timer.Add_Tick({ Invoke-SelfTestTick })
}
else {
    $script:Timer.Add_Tick({ Invoke-GuardTick })
}


function Add-SelfTestResult {
    param([bool]$Ok, [string]$Name, [string]$Detail)
    $tag = 'PASS'
    if (-not $Ok) { $tag = 'FAIL'; $script:SelfTestFailed = $true }
    $script:SelfTestLog.Add(("[{0}] {1}：{2}" -f $tag, $Name, $Detail))
}

function Invoke-SelfTestTick {
    try {
        switch ($script:SelfTestStep) {
            0 {
                $b = $script:Form.Bounds
                Add-SelfTestResult (($b.Width -ge $primary.Width) -and ($b.Height -ge $primary.Height)) '遮罩尺寸' ("{0}x{1}" -f $b.Width, $b.Height)
                Add-SelfTestResult ($script:Form.Controls.Count -ge 1) '界面构建' ("控件数 {0}" -f $script:Form.Controls.Count)
                $tickNow = [ScreenLockNative]::GetLastInputTick()
                
                Add-SelfTestResult (($tickNow -ne 0) -and ($tickNow -ne [uint32]::MaxValue)) '输入空闲接口' ("tick={0}, idle={1}ms" -f $tickNow, [ScreenLockNative]::GetIdleMilliseconds())
                $script:Txt.Text = 'wrong-password'
                Invoke-SubmitAttempt
                Add-SelfTestResult (($script:Txt.Text.Length -eq 0) -and $script:TxtError.Visible -and ($script:FailCount -eq 1)) '错误密码处理' ("已清空输入、显示提示、计数={0}" -f $script:FailCount)
            }
            1 {
                $script:Txt.Text = 'selftest-dummy-pw'
                Invoke-SubmitAttempt
                Add-SelfTestResult ($script:AllowClose -and (-not $script:Form.Visible)) '正确密码解锁' ("AllowClose={0}, 窗口可见={1}" -f $script:AllowClose, $script:Form.Visible)
            }
            2 {
                Add-SelfTestResult (-not $script:Form.Visible) '窗口已关闭' '（走到这一步说明解锁没有生效）'
                if ($script:Form.Visible) {
                    $script:AllowClose = $true
                    $script:Form.Close()
                }
                $script:Timer.Stop()
            }
        }
        $script:SelfTestStep++
    }
    catch {
        $script:SelfTestLog.Add('[FAIL] 自检异常：' + $_.Exception.Message)
        $script:SelfTestFailed = $true
        $script:AllowClose = $true
        try { $script:Form.Close() } catch { }
    }
}

if ($SelfTest) {
    $tmpDir = Join-Path $env:TEMP ('ScreenLockSelfTest_' + [guid]::NewGuid().ToString('N'))
    try {
        New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null
        $savedCandidates = $script:ConfigCandidates
        $script:ConfigCandidates = New-Object System.Collections.Generic.List[string]
        [void]$script:ConfigCandidates.Add((Join-Path $tmpDir '.screenlock.config.json'))
        $null = Save-PasswordConfig -Record $script:Config
        $reloaded = Read-PasswordConfig
        Add-SelfTestResult (($null -ne $reloaded) -and (Test-PasswordRecord -Password 'selftest-dummy-pw' -Record $reloaded)) '配置文件读写' "目录 $tmpDir"
        Add-SelfTestResult (-not (Test-PasswordRecord -Password 'wrong' -Record $script:Config)) '错误密码不会被接受' 'PBKDF2 校验'

        
        $savedReg = $script:StoreRegPath
        $savedMirror = $script:StoreMirrorPath
        $script:StoreRegPath = 'HKCU:\Software\CAScreenGuardSelfTest'
        $script:StoreMirrorPath = Join-Path $tmpDir 'store.json'
        try {
            $fake = New-IntegrityStore
            $null = Write-IntegrityStore -Store $fake
            $rec = New-PasswordRecord -Password 'selftest-dummy-pw' -Auth $fake
            $null = Save-PasswordConfig -Record $rec -Store $fake
            $reread = Read-PasswordConfig
            $v1 = Test-ConfigIntegrity -ConfigRecord $reread -RawText $script:ConfigRaw
            (Get-Item -LiteralPath $script:ConfigPath -Force).Attributes = [System.IO.FileAttributes]::Normal
            [System.IO.File]::WriteAllText($script:ConfigPath, ($script:ConfigRaw.Replace('"created"', '"createdX"')), (New-Object System.Text.UTF8Encoding($false)))
            $tampered = Read-PasswordConfig
            $v2 = Test-ConfigIntegrity -ConfigRecord $tampered -RawText $script:ConfigRaw
            Remove-Item -LiteralPath $script:ConfigPath -Force
            $v3 = Test-ConfigIntegrity -ConfigRecord (Read-PasswordConfig) -RawText $null
            Add-SelfTestResult (($v1 -eq 'ok') -and ($v2 -eq 'modified') -and ($v3 -eq 'deleted')) '配置完整性判定' ("正常={0} / 被改={1} / 被删={2}" -f $v1, $v2, $v3)
        }
        catch {
            Add-SelfTestResult $false '配置完整性判定' $_.Exception.Message
        }
        finally {
            $script:StoreRegPath = $savedReg
            $script:StoreMirrorPath = $savedMirror
            Remove-Item -LiteralPath 'HKCU:\Software\CAScreenGuardSelfTest' -Recurse -Force -ErrorAction SilentlyContinue
        }

        $script:ConfigCandidates = $savedCandidates
    }
    catch {
        Add-SelfTestResult $false '配置文件读写' $_.Exception.Message
    }
    finally {
        Remove-Item -LiteralPath $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}




try {
    
    $runMode = '熄屏锁屏'
    if ($SelfTest) { $runMode = '自检' }
    elseif ($script:AutoReset) { $runMode = '改密码' }
    $hookState = '开'
    if ($NoKeyboardHook) { $hookState = '关' }
    Write-GuardLog ('启动：版本 ' + $script:AppVersion + '，Lang=' + $script:Lang + '，模式=' + $runMode + '，键盘钩子=' + $hookState)

    if (-not $SelfTest) { Initialize-SystemState }

    $script:Form.Show()
    
    [ScreenLockNative]::TargetWindow = $script:Form.Handle
    if (-not $SelfTest) { New-RunningFlag }   
    if (-not $SelfTest) {
        if ($script:AutoReset) {
            
            
            Install-WallpaperBackground
            $script:State = 'Prompt'
        }
        else {
            [ScreenLockNative]::MonitorOff()
            
            
            
            try {
                $deadline = (Get-Date).AddSeconds(1)
                while ((Get-Date) -lt $deadline) {
                    [System.Windows.Forms.Application]::DoEvents()
                    Start-Sleep -Milliseconds 50
                }
            } catch { }
            Install-WallpaperBackground
            $script:State = 'Away'
            $script:BlankTick = [ScreenLockNative]::GetLastInputTick()
            $script:LastBlankSent = Get-Date
        }
    }
    else {
        $script:State = 'Prompt'
    }

    if ($script:AutoReset -and -not $SelfTest) { Invoke-ChangePasswordFlow }

    $script:Timer.Start()
    [System.Windows.Forms.Application]::Run($script:Form)
}
catch {
    $msg = $_.Exception.Message

    if (-not $SelfTest) { $null = Write-CrashLog -ErrorRecord $_ -Where 'run' }
    try { $script:SelfTestFailed = $true } catch { }
    Write-GuardLog ('异常退出：' + $_.Exception.GetType().Name + ' - ' + $msg)
    try {
        [System.Windows.Forms.MessageBox]::Show($msg, (T 'k58'), 'OK', 'Error') | Out-Null
    }
    catch { }
}
finally {
    $script:AllowClose = $true
    Stop-SingleInstance
    try { $script:Timer.Stop() } catch { }
    try { $script:Form.Dispose() } catch { }
    try { if ($script:Wallpaper) { $script:Wallpaper.Dispose() } } catch { }   
    try { if ($script:WordmarkImg) { $script:WordmarkImg.Dispose() } } catch { }   
    Restore-SystemState        
    
    try { Write-GuardLog ('退出：存活 ' + [int]((Get-Date) - $script:StartedAt).TotalSeconds + ' 秒') } catch { }
    if ($SelfTest) {
        Write-Host ''
        Write-Host '================ CAScreenGuard 自检结果 ================'
        foreach ($line in $script:SelfTestLog) { Write-Host $line }
        Write-Host '================================================'
        if ($script:SelfTestFailed) {
            Write-Host '结论：存在失败项。'
            exit 1
        }
        else {
            Write-Host '结论：全部通过。（本模式未改动显示器电源）'
            exit 0
        }
    }
}
