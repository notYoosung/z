# Nickname Mod for Minetest

Add a nickname to the player(nametag) in minetest.

grant your nickname privilege first. now it's the default to common user.

```
/grantme nickname
```

## Chat commands

### `/nickname[ your_nickname[, player_name]]`

Get or set the nickname.

Only You can specify the player_name if you have the `server` privilege. If the value is "?", which means show the `player_name`'s nickname.

### `/nickname_color[ color[, player_name]]`

Get or set the nickname's color.

Only You can specify the player_name if you have the `server` privilege. If the value is "?", which means show the `player_name`'s nickname color.

### `/nickname_bgcolor[ color[, player_name]]`

Get or set the nickname's background color.

Only You can specify the player_name if you have the `server` privilege. If the value is "?", which means show the `player_name`'s nickname bgcolor.

## Color


* Specified in the form of `RGB`red, green, and blue three-component. R: red component; G: green component; B: blue component; A: alpha transparency value
  * `#RGB` defines a color in hexadecimal format.
  * `#RGBA` defines a color in hexadecimal format and alpha channel.
  * `#RRGGBB` defines the color in hexadecimal format.
  * `#RRGGBBAA` defines the color in hexadecimal format and alpha channel.
* Specify by color name (see the table below for the name)
  * Support named colors of [CSS Color Module Level 4](https://www.w3.org/TR/css-color-4/#named-color).
  * To specify a value for the `alpha channel`, append `#A` or `#AA` to the end of the color name (e.g. `red#08`).

<table class="reference">
<tbody><tr>
<th align="left" width="25%">Color Name</th>
<th align="left" width="15%">HEX</th>
<th align="left" width="43%">Color</th>

</tr>

<tr>
<td align="left" style="color:AliceBlue" bgcolor="grey">AliceBlue&nbsp;</td>
<td align="left">#F0F8FF</td>
<td bgcolor="#F0F8FF">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:AntiqueWhite" bgcolor="grey">AntiqueWhite&nbsp;</td>
<td align="left">#FAEBD7</td>
<td bgcolor="#FAEBD7">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:Aqua" bgcolor="grey">Aqua&nbsp;</td>
<td align="left">#00FFFF</td>
<td bgcolor="#00FFFF">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:Aquamarine" bgcolor="grey">Aquamarine&nbsp;</td>
<td align="left">#7FFFD4</td>
<td bgcolor="#7FFFD4">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:Azure" bgcolor="grey">Azure&nbsp;</td>
<td align="left">#F0FFFF</td>
<td bgcolor="#F0FFFF">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:Beige" bgcolor="grey">Beige&nbsp;</td>
<td align="left">#F5F5DC</td>
<td bgcolor="#F5F5DC">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:Bisque" bgcolor="grey">Bisque&nbsp;</td>
<td align="left">#FFE4C4</td>
<td bgcolor="#FFE4C4">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:Black">Black&nbsp;</td>
<td align="left">#000000</td>
<td bgcolor="#000000">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:BlanchedAlmond" bgcolor="grey">BlanchedAlmond&nbsp;</td>
<td align="left">#FFEBCD</td>
<td bgcolor="#FFEBCD">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:Blue">Blue&nbsp;</td>
<td align="left">#0000FF</td>
<td bgcolor="#0000FF">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:BlueViolet">BlueViolet&nbsp;</td>
<td align="left">#8A2BE2</td>
<td bgcolor="#8A2BE2">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:Brown">Brown&nbsp;</td>
<td align="left">#A52A2A</td>
<td bgcolor="#A52A2A">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:BurlyWood">BurlyWood&nbsp;</td>
<td align="left">#DEB887</td>
<td bgcolor="#DEB887">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:CadetBlue">CadetBlue&nbsp;</td>
<td align="left">#5F9EA0</td>
<td bgcolor="#5F9EA0">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:Chartreuse">Chartreuse&nbsp;</td>
<td align="left">#7FFF00</td>
<td bgcolor="#7FFF00">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:Chocolate">Chocolate&nbsp;</td>
<td align="left">#D2691E</td>
<td bgcolor="#D2691E">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:Coral">Coral&nbsp;</td>
<td align="left">#FF7F50</td>
<td bgcolor="#FF7F50">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:CornflowerBlue">CornflowerBlue&nbsp;</td>
<td align="left">#6495ED</td>
<td bgcolor="#6495ED">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:Cornsilk" bgcolor="grey">Cornsilk&nbsp;</td>
<td align="left">#FFF8DC</td>
<td bgcolor="#FFF8DC">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:Crimson">Crimson&nbsp;</td>
<td align="left">#DC143C</td>
<td bgcolor="#DC143C">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:Cyan">Cyan&nbsp;</td>
<td align="left">#00FFFF</td>
<td bgcolor="#00FFFF">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:DarkBlue">DarkBlue&nbsp;</td>
<td align="left">#00008B</td>
<td bgcolor="#00008B">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:DarkCyan">DarkCyan&nbsp;</td>
<td align="left">#008B8B</td>
<td bgcolor="#008B8B">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:DarkGoldenRod">DarkGoldenRod&nbsp;</td>
<td align="left">#B8860B</td>
<td bgcolor="#B8860B">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:DarkGray">DarkGray&nbsp;</td>
<td align="left">#A9A9A9</td>
<td bgcolor="#A9A9A9">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:DarkGreen">DarkGreen&nbsp;</td>
<td align="left">#006400</td>
<td bgcolor="#006400">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:DarkKhaki">DarkKhaki&nbsp;</td>
<td align="left">#BDB76B</td>
<td bgcolor="#BDB76B">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:DarkMagenta">DarkMagenta&nbsp;</td>
<td align="left">#8B008B</td>
<td bgcolor="#8B008B">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:DarkOliveGreen">DarkOliveGreen&nbsp;</td>
<td align="left">#556B2F</td>
<td bgcolor="#556B2F">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:DarkOrange">DarkOrange&nbsp;</td>
<td align="left">#FF8C00</td>
<td bgcolor="#FF8C00">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:DarkOrchid">DarkOrchid&nbsp;</td>
<td align="left">#9932CC</td>
<td bgcolor="#9932CC">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:DarkRed">DarkRed&nbsp;</td>
<td align="left">#8B0000</td>
<td bgcolor="#8B0000">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:DarkSalmon">DarkSalmon&nbsp;</td>
<td align="left">#E9967A</td>
<td bgcolor="#E9967A">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:DarkSeaGreen">DarkSeaGreen&nbsp;</td>
<td align="left">#8FBC8F</td>
<td bgcolor="#8FBC8F">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:DarkSlateBlue">DarkSlateBlue&nbsp;</td>
<td align="left">#483D8B</td>
<td bgcolor="#483D8B">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:DarkSlateGray">DarkSlateGray&nbsp;</td>
<td align="left">#2F4F4F</td>
<td bgcolor="#2F4F4F">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:DarkTurquoise">DarkTurquoise&nbsp;</td>
<td align="left">#00CED1</td>
<td bgcolor="#00CED1">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:DarkViolet">DarkViolet&nbsp;</td>
<td align="left">#9400D3</td>
<td bgcolor="#9400D3">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:DeepPink">DeepPink&nbsp;</td>
<td align="left">#FF1493</td>
<td bgcolor="#FF1493">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:DeepSkyBlue">DeepSkyBlue&nbsp;</td>
<td align="left">#00BFFF</td>
<td bgcolor="#00BFFF">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:DimGray">DimGray&nbsp;</td>
<td align="left">#696969</td>
<td bgcolor="#696969">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:DodgerBlue">DodgerBlue&nbsp;</td>
<td align="left">#1E90FF</td>
<td bgcolor="#1E90FF">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:FireBrick">FireBrick&nbsp;</td>
<td align="left">#B22222</td>
<td bgcolor="#B22222">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:FloralWhite" bgcolor="grey">FloralWhite&nbsp;</td>
<td align="left">#FFFAF0</td>
<td bgcolor="#FFFAF0">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:ForestGreen">ForestGreen&nbsp;</td>
<td align="left">#228B22</td>
<td bgcolor="#228B22">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:Fuchsia">Fuchsia&nbsp;</td>
<td align="left">#FF00FF</td>
<td bgcolor="#FF00FF">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:Gainsboro" bgcolor="grey">Gainsboro&nbsp;</td>
<td align="left">#DCDCDC</td>
<td bgcolor="#DCDCDC">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:GhostWhite" bgcolor="grey">GhostWhite&nbsp;</td>
<td align="left">#F8F8FF</td>
<td bgcolor="#F8F8FF">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:Gold">Gold&nbsp;</td>
<td align="left">#FFD700</td>
<td bgcolor="#FFD700">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:GoldenRod">GoldenRod&nbsp;</td>
<td align="left">#DAA520</td>
<td bgcolor="#DAA520">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:Gray">Gray&nbsp;</td>
<td align="left">#808080</td>
<td bgcolor="#808080">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:Green">Green&nbsp;</td>
<td align="left">#008000</td>
<td bgcolor="#008000">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:GreenYellow">GreenYellow&nbsp;</td>
<td align="left">#ADFF2F</td>
<td bgcolor="#ADFF2F">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:HoneyDew" bgcolor="grey">HoneyDew&nbsp;</td>
<td align="left">#F0FFF0</td>
<td bgcolor="#F0FFF0">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:HotPink">HotPink&nbsp;</td>
<td align="left">#FF69B4</td>
<td bgcolor="#FF69B4">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:IndianRed ">IndianRed &nbsp;</td>
<td align="left">#CD5C5C</td>
<td bgcolor="#CD5C5C">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:Indigo  ">Indigo  &nbsp;</td>
<td align="left">#4B0082</td>
<td bgcolor="#4B0082">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:Ivory" bgcolor="grey">Ivory&nbsp;</td>
<td align="left">#FFFFF0</td>
<td bgcolor="#FFFFF0">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:Khaki">Khaki&nbsp;</td>
<td align="left">#F0E68C</td>
<td bgcolor="#F0E68C">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:Lavender" bgcolor="grey">Lavender&nbsp;</td>
<td align="left">#E6E6FA</td>
<td bgcolor="#E6E6FA">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:LavenderBlush" bgcolor="grey">LavenderBlush&nbsp;</td>
<td align="left">#FFF0F5</td>
<td bgcolor="#FFF0F5">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:LawnGreen">LawnGreen&nbsp;</td>
<td align="left">#7CFC00</td>
<td bgcolor="#7CFC00">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:LemonChiffon" bgcolor="grey">LemonChiffon&nbsp;</td>
<td align="left">#FFFACD</td>
<td bgcolor="#FFFACD">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:LightBlue">LightBlue&nbsp;</td>
<td align="left">#ADD8E6</td>
<td bgcolor="#ADD8E6">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:LightCoral">LightCoral&nbsp;</td>
<td align="left">#F08080</td>
<td bgcolor="#F08080">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:LightCyan" bgcolor="grey">LightCyan&nbsp;</td>
<td align="left">#E0FFFF</td>
<td bgcolor="#E0FFFF">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:LightGoldenRodYellow" bgcolor="grey">LightGoldenRodYellow&nbsp;</td>
<td align="left">#FAFAD2</td>
<td bgcolor="#FAFAD2">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:LightGray">LightGray&nbsp;</td>
<td align="left">#D3D3D3</td>
<td bgcolor="#D3D3D3">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:LightGreen">LightGreen&nbsp;</td>
<td align="left">#90EE90</td>
<td bgcolor="#90EE90">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:LightPink">LightPink&nbsp;</td>
<td align="left">#FFB6C1</td>
<td bgcolor="#FFB6C1">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:LightSalmon">LightSalmon&nbsp;</td>
<td align="left">#FFA07A</td>
<td bgcolor="#FFA07A">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:LightSeaGreen">LightSeaGreen&nbsp;</td>
<td align="left">#20B2AA</td>
<td bgcolor="#20B2AA">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:LightSkyBlue">LightSkyBlue&nbsp;</td>
<td align="left">#87CEFA</td>
<td bgcolor="#87CEFA">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:LightSlateGray">LightSlateGray&nbsp;</td>
<td align="left">#778899</td>
<td bgcolor="#778899">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:LightSteelBlue">LightSteelBlue&nbsp;</td>
<td align="left">#B0C4DE</td>
<td bgcolor="#B0C4DE">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:LightYellow" bgcolor="grey">LightYellow&nbsp;</td>
<td align="left">#FFFFE0</td>
<td bgcolor="#FFFFE0">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:Lime">Lime&nbsp;</td>
<td align="left">#00FF00</td>
<td bgcolor="#00FF00">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:LimeGreen">LimeGreen&nbsp;</td>
<td align="left">#32CD32</td>
<td bgcolor="#32CD32">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:Linen" bgcolor="grey">Linen&nbsp;</td>
<td align="left">#FAF0E6</td>
<td bgcolor="#FAF0E6">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:Magenta">Magenta&nbsp;</td>
<td align="left">#FF00FF</td>
<td bgcolor="#FF00FF">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:Maroon">Maroon&nbsp;</td>
<td align="left">#800000</td>
<td bgcolor="#800000">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:MediumAquaMarine">MediumAquaMarine&nbsp;</td>
<td align="left">#66CDAA</td>
<td bgcolor="#66CDAA">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:MediumBlue">MediumBlue&nbsp;</td>
<td align="left">#0000CD</td>
<td bgcolor="#0000CD">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:MediumOrchid">MediumOrchid&nbsp;</td>
<td align="left">#BA55D3</td>
<td bgcolor="#BA55D3">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:MediumPurple">MediumPurple&nbsp;</td>
<td align="left">#9370DB</td>
<td bgcolor="#9370DB">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:MediumSeaGreen">MediumSeaGreen&nbsp;</td>
<td align="left">#3CB371</td>
<td bgcolor="#3CB371">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:MediumSlateBlue">MediumSlateBlue&nbsp;</td>
<td align="left">#7B68EE</td>
<td bgcolor="#7B68EE">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:MediumSpringGreen">MediumSpringGreen&nbsp;</td>
<td align="left">#00FA9A</td>
<td bgcolor="#00FA9A">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:MediumTurquoise">MediumTurquoise&nbsp;</td>
<td align="left">#48D1CC</td>
<td bgcolor="#48D1CC">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:MediumVioletRed">MediumVioletRed&nbsp;</td>
<td align="left">#C71585</td>
<td bgcolor="#C71585">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:MidnightBlue">MidnightBlue&nbsp;</td>
<td align="left">#191970</td>
<td bgcolor="#191970">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:MintCream" bgcolor="grey">MintCream&nbsp;</td>
<td align="left">#F5FFFA</td>
<td bgcolor="#F5FFFA">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:MistyRose" bgcolor="grey">MistyRose&nbsp;</td>
<td align="left">#FFE4E1</td>
<td bgcolor="#FFE4E1">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:Moccasin" bgcolor="grey">Moccasin&nbsp;</td>
<td align="left">#FFE4B5</td>
<td bgcolor="#FFE4B5">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:NavajoWhite" bgcolor="grey">NavajoWhite&nbsp;</td>
<td align="left">#FFDEAD</td>
<td bgcolor="#FFDEAD">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:Navy">Navy&nbsp;</td>
<td align="left">#000080</td>
<td bgcolor="#000080">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:OldLace" bgcolor="grey">OldLace&nbsp;</td>
<td align="left">#FDF5E6</td>
<td bgcolor="#FDF5E6">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:Olive">Olive&nbsp;</td>
<td align="left">#808000</td>
<td bgcolor="#808000">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:OliveDrab">OliveDrab&nbsp;</td>
<td align="left">#6B8E23</td>
<td bgcolor="#6B8E23">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:Orange">Orange&nbsp;</td>
<td align="left">#FFA500</td>
<td bgcolor="#FFA500">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:OrangeRed">OrangeRed&nbsp;</td>
<td align="left">#FF4500</td>
<td bgcolor="#FF4500">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:Orchid">Orchid&nbsp;</td>
<td align="left">#DA70D6</td>
<td bgcolor="#DA70D6">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:PaleGoldenRod" bgcolor="grey">PaleGoldenRod&nbsp;</td>
<td align="left">#EEE8AA</td>
<td bgcolor="#EEE8AA">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:PaleGreen">PaleGreen&nbsp;</td>
<td align="left">#98FB98</td>
<td bgcolor="#98FB98">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:PaleTurquoise">PaleTurquoise&nbsp;</td>
<td align="left">#AFEEEE</td>
<td bgcolor="#AFEEEE">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:PaleVioletRed">PaleVioletRed&nbsp;</td>
<td align="left">#DB7093</td>
<td bgcolor="#DB7093">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:PapayaWhip" bgcolor="grey">PapayaWhip&nbsp;</td>
<td align="left">#FFEFD5</td>
<td bgcolor="#FFEFD5">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:PeachPuff">PeachPuff&nbsp;</td>
<td align="left">#FFDAB9</td>
<td bgcolor="#FFDAB9">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:Peru">Peru&nbsp;</td>
<td align="left">#CD853F</td>
<td bgcolor="#CD853F">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:Pink">Pink&nbsp;</td>
<td align="left">#FFC0CB</td>
<td bgcolor="#FFC0CB">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:Plum">Plum&nbsp;</td>
<td align="left">#DDA0DD</td>
<td bgcolor="#DDA0DD">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:PowderBlue">PowderBlue&nbsp;</td>
<td align="left">#B0E0E6</td>
<td bgcolor="#B0E0E6">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:Purple">Purple&nbsp;</td>
<td align="left">#800080</td>
<td bgcolor="#800080">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:Red">Red&nbsp;</td>
<td align="left">#FF0000</td>
<td bgcolor="#FF0000">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:RosyBrown">RosyBrown&nbsp;</td>
<td align="left">#BC8F8F</td>
<td bgcolor="#BC8F8F">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:RoyalBlue">RoyalBlue&nbsp;</td>
<td align="left">#4169E1</td>
<td bgcolor="#4169E1">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:SaddleBrown">SaddleBrown&nbsp;</td>
<td align="left">#8B4513</td>
<td bgcolor="#8B4513">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:Salmon">Salmon&nbsp;</td>
<td align="left">#FA8072</td>
<td bgcolor="#FA8072">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:SandyBrown">SandyBrown&nbsp;</td>
<td align="left">#F4A460</td>
<td bgcolor="#F4A460">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:SeaGreen">SeaGreen&nbsp;</td>
<td align="left">#2E8B57</td>
<td bgcolor="#2E8B57">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:SeaShell" bgcolor="grey">SeaShell&nbsp;</td>
<td align="left">#FFF5EE</td>
<td bgcolor="#FFF5EE">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:Sienna">Sienna&nbsp;</td>
<td align="left">#A0522D</td>
<td bgcolor="#A0522D">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:Silver">Silver&nbsp;</td>
<td align="left">#C0C0C0</td>
<td bgcolor="#C0C0C0">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:SkyBlue">SkyBlue&nbsp;</td>
<td align="left">#87CEEB</td>
<td bgcolor="#87CEEB">&nbsp;</td>
</tr>


<tr>
<td align="left" style="color:SlateBlue">SlateBlue&nbsp;</td>
<td align="left">#6A5ACD</td>
<td bgcolor="#6A5ACD">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:SlateGray">SlateGray&nbsp;</td>
<td align="left">#708090</td>
<td bgcolor="#708090">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:Snow" bgcolor="grey">Snow&nbsp;</td>
<td align="left">#FFFAFA</td>
<td bgcolor="#FFFAFA">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:SpringGreen">SpringGreen&nbsp;</td>
<td align="left">#00FF7F</td>
<td bgcolor="#00FF7F">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:SteelBlue">SteelBlue&nbsp;</td>
<td align="left">#4682B4</td>
<td bgcolor="#4682B4">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:Tan">Tan&nbsp;</td>
<td align="left">#D2B48C</td>
<td bgcolor="#D2B48C">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:Teal">Teal&nbsp;</td>
<td align="left">#008080</td>
<td bgcolor="#008080">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:Thistle">Thistle&nbsp;</td>
<td align="left">#D8BFD8</td>
<td bgcolor="#D8BFD8">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:Tomato">Tomato&nbsp;</td>
<td align="left">#FF6347</td>
<td bgcolor="#FF6347">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:Turquoise">Turquoise&nbsp;</td>
<td align="left">#40E0D0</td>
<td bgcolor="#40E0D0">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:Violet">Violet&nbsp;</td>
<td align="left">#EE82EE</td>
<td bgcolor="#EE82EE">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:Wheat" bgcolor="grey">Wheat&nbsp;</td>
<td align="left">#F5DEB3</td>
<td bgcolor="#F5DEB3">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:White" bgcolor="grey">White&nbsp;</td>
<td align="left">#FFFFFF</td>
<td bgcolor="#FFFFFF">&nbsp;</td>


</tr>


<tr>
<td align="left" style="color:WhiteSmoke" bgcolor="grey">WhiteSmoke&nbsp;</td>
<td align="left">#F5F5F5</td>
<td bgcolor="#F5F5F5">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:Yellow" bgcolor="grey">Yellow&nbsp;</td>
<td align="left">#FFFF00</td>
<td bgcolor="#FFFF00">&nbsp;</td>

</tr>


<tr>
<td align="left" style="color:YellowGreen">YellowGreen&nbsp;</td>
<td align="left">#9ACD32</td>
<td bgcolor="#9ACD32">&nbsp;</td>

</tr>
</tbody></table>

## LICENSE

MIT
