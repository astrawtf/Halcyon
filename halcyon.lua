--[[ Halcyon UI Library (Roblox / Luau)
	local Lib = loadstring(game:HttpGet("RAW_URL"))()
	Lib:Loading{...}  ->  Lib:Window{...}  ->  win:Tab{Name, Icon = "lucide-name", ...}
	tab:Section/Toggle/Slider/Dropdown/MultiDropdown/ColorPicker/Input/Button/Keybind
	Any element accepts Icon = "lucide-name" (shows a small tile next to its label); Input accepts InputIcon = "name"|false.
	Icons: all 1,573 Lucide icons are built in (names match lucide.dev). Lib:RegisterIcon("mine", "rbxassetid://123") adds your own.
	Lib:Notify{Title, Text, Type = "Info"|"Success"|"Warning"|"Error", Duration}
	Values live in Lib.Flags[Flag or Name] and are saved automatically (colors as hex strings, read them with Lib:GetColor(flag)).

	Crispness rules this file follows (Roblox rasterizes text per pixel, so anything fractional or re-rendered turns it soft):
	 * every Position/Size that touches text is a whole number of pixels (px()), and windows are placed with offsets, never scale-centered
	 * no CanvasGroup and no UIScale around text; fades tween each descendant's transparency instead (fade())
	 * integer TextSize only, one typeface (Inter) with Medium/Bold weights, icons drawn from 48px sprites at 16px (an exact 3:1 reduction)
]]
local UIS, TS, HS, TXT, PL = game:GetService("UserInputService"), game:GetService("TweenService"), game:GetService("HttpService"), game:GetService("TextService"), game:GetService("Players")
local U, O, Sc, V2 = UDim2.new, UDim2.fromOffset, UDim2.fromScale, Vector2.new
local CEN, RIGHT, AX, AY, AXY = Enum.TextXAlignment.Center, Enum.TextXAlignment.Right, Enum.AutomaticSize.X, Enum.AutomaticSize.Y, Enum.AutomaticSize.XY
local MED, BOLD = Enum.FontWeight.Medium, Enum.FontWeight.Bold
local QUINT, LINEAR = Enum.EasingStyle.Quint, Enum.EasingStyle.Linear

local Lib = {Flags = {}, Saved = {}, Setters = {}, Conns = {}, Guis = {}, Icons = {}, Themes = {}, Folder = "Halcyon", Config = "default",
	FontFamily = "rbxassetid://12187365364", -- Inter
	Mono = Font.fromEnum(Enum.Font.RobotoMono)}
function Lib.Font(w) return Font.new(Lib.FontFamily, w or Enum.FontWeight.Regular) end

-- Lucide sprites (48px sheets): name,x,y; grouped by sheet asset id -------------------------------------------------
local SHEETS = {
	[16898613699] = "rewind,563,967;refresh-ccw-dot,869,404;person-standing,563,771;rotate-cw,869,453;picture-in-picture,257,869;phone-call,514,820;server-crash,918,955;scatter-chart,196,967;pointer,661,771;rail-symbol,967,514;scaling,967,661;presentation,771,196;popsicle,563,869;repeat-1,918,612;screen-share-off,771,906;rat,869,612;separator-horizontal,918,906;phone-missed,771,98;qr-code,967,257;receipt-russian-ruble,514,967;rectangle-ellipsis,820,196;reply,612,918;pause,0,771;radius,257,967;pilcrow,612,771;scan-face,820,808;pause-octagon,771,0;receipt-japanese-yen,612,869;rabbit,869,355;scissors-square,869,808;route,404,918;plane-landing,771,147;search,918,857;send-to-back,820,955;send,967,857;pentagon,771,306;pen-tool,820,0;pencil-ruler,0,820;rotate-3d,147,918;popcorn,612,820;rainbow,918,563;separator-vertical,869,955;satellite,147,967;server-off,967,955;plug-2,869,306;radio,306,918;plug-zap,771,404;replace-all,771,759;receipt-swiss-franc,967,49;scan-text,661,967;ruler,710,869;plug,404,771;podcast,820,612;pocket,869,563;printer,196,771;replace,710,820;scan-search,710,918;route-off,453,869;quote,918,306;salad,967,147;pilcrow-square,771,612;receipt-indian-rupee,661,820;scroll-text,967,759;rectangle-horizontal,196,820;pipette,869,49;puzzle,49,918;power-circle,967,0;plus,257,918;scissors-square-dashed-bottom,918,759;remove-formatting,967,563;send-horizontal,869,906;rocket,918,147;rows-2,967,612;pen-square,514,771;projector,147,820;rows,820,759;rows-4,869,710;scale-3d,453,918;satellite-dish,196,918;pizza,820,98;pc-case,257,771;school,453,967;rotate-ccw,967,355;phone-incoming,820,49;scan-eye,869,759;ribbon,967,98;percent,771,563;receipt-cent,771,710;ratio,820,661;proportions,98,869;plane,98,820;rotate-ccw-square,98,967;power,820,147;piggy-bank,820,563;plane-takeoff,147,771;receipt-euro,710,771;russian-ruble,661,918;scissors-line-dashed,967,710;plus-circle,355,820;pyramid,0,967;refresh-cw-off,453,820;piano,771,355;picture-in-picture-2,306,820;pencil-line,49,771;pi,820,306;play-square,0,918;roller-coaster,196,869;refresh-cw,404,869;rotate-cw-square,918,404;scale,404,967;power-square,869,98;scan-line,771,857;refresh-ccw,820,453;radio-receiver,404,820;receipt,869,147;power-off,918,49;server-cog,967,906;search-x,967,808;radio-tower,355,869;router,355,967;regex,306,967;plug-zap-2,820,355;save,918,453;play,918,257;phone,0,869;repeat,820,710;screen-share,710,967;play-circle,49,869;rows-3,918,661;sandwich,918,196;receipt-pound-sterling,563,918;scan,967,196;redo-2,49,967;search-code,820,906;pocket-knife,918,514;reply-all,661,869;search-slash,771,955;sailboat,612,967;pie-chart,869,514;redo,918,355;radar,820,404;pickaxe,355,771;scan-barcode,918,710;refrigerator,355,918;plus-square,306,869;save-all,967,404;pen,771,49;paw-print,771,257;percent-circle,306,771;receipt-text,918,98;phone-off,98,771;pi-square,869,257;percent-square,820,514;pill,563,820;pin-off,514,869;pound-sterling,514,918;pointer-off,771,661;scissors,820,857;radiation,771,453;radical,453,771;rectangle-vertical,147,869;rss,771,808;rocking-chair,869,196;school-2,967,453;search-check,869,857;percent-diamond,257,820;pencil,820,257;repeat-2,869,661;pin,918,0;redo-dot,967,306;phone-forwarded,869,0;recycle,98,918;phone-outgoing,49,820;scroll,918,808;pen-line,771,514;",
	[16898613353] = "fuel,196,967;gavel,967,808;feather,771,98;framer,661,967;file-lock-2,257,918;file-down,98,820;folder-plus,661,918;flame,967,306;file-warning,967,514;flip-horizontal,306,967;folder-output,771,808;folder-search,918,196;flask-round,404,869;flag,98,918;file-pen-line,612,820;flip-vertical,918,612;file-key-2,404,771;facebook,563,771;fish,869,147;files,771,710;file-scan,820,147;file-minus-2,869,563;fence,98,771;ellipsis,771,49;folder-key,355,967;folder-tree,967,404;folder-input,453,869;fish-off,967,49;fold-vertical,661,869;equal-not,49,771;file-symlink,967,257;forward,771,857;file-up,453,771;git-branch-plus,967,857;file-text,869,355;folder-up,918,453;file-audio,771,355;flag-off,820,196;gallery-horizontal-end,967,710;flip-vertical-2,967,563;file-bar-chart-2,869,514;file-music,771,661;folder-lock,967,612;equal,0,820;egg,514,771;file-terminal,918,306;flask-conical,453,820;folder-sync,147,967;fingerprint,563,918;frame,710,918;folder-root,612,967;ferris-wheel,49,820;function-square,453,967;folders,967,661;folder-kanban,404,918;file-type-2,820,404;file-code,869,49;flashlight,869,404;file-type,771,453;file-video-2,404,820;file-x,869,612;folder-minus,918,661;file-code-2,918,0;folder-open-dot,869,710;file-spreadsheet,49,918;gamepad,967,759;file-badge,257,869;file-minus,820,612;folder-open,820,759;file-pen,563,869;git-compare-arrows,918,955;file-pie-chart,514,918;gem,918,857;folder-check,563,967;file-json,771,404;folder-heart,869,453;gauge-circle,820,906;gallery-vertical,771,906;folder-archive,612,918;folder-symlink,196,918;folder-search-2,967,147;fan,869,0;flag-triangle-right,147,869;forklift,869,759;folder,404,967;file-volume-2,306,918;file-box,771,612;filter,612,869;file-axis-3d,355,771;earth-lock,771,0;footprints,918,710;gantt-chart-square,918,808;file-key,355,820;flower-2,869,661;film,710,771;file,820,661;euro,771,306;file-sliders,98,869;frown,967,196;earth,0,771;folder-git-2,967,355;expand,306,771;flashlight-off,918,355;file-plus-2,967,0;egg-off,771,514;eye-off,820,514;factory,514,820;fast-forward,820,49;file-audio-2,820,306;file-check,563,820;file-cog,820,98;file-diff,771,147;file-digit,147,771;eraser,820,257;file-line-chart,306,869;file-input,869,306;eye,771,563;file-volume,257,967;file-x-2,918,563;flag-triangle-left,196,820;flower,820,710;fold-horizontal,710,820;folder-closed,918,147;folder-dot,196,869;focus,771,759;folder-x,453,918;form-input,820,808;gallery-horizontal,918,759;gallery-vertical-end,820,857;file-image,918,257;gallery-thumbnails,869,808;ghost,869,906;git-compare,967,955;folder-edit,98,967;git-branch,918,906;file-question,869,98;file-bar-chart,820,563;file-badge-2,306,820;ellipsis-vertical,820,0;gantt-chart,869,857;file-clock,514,869;gauge,771,955;egg-fried,257,771;git-commit-vertical,967,906;file-stack,0,967;external-link,257,820;file-archive,869,257;flip-horizontal-2,355,918;file-signature,147,820;fish-symbol,918,98;file-search,196,771;file-search-2,771,196;filter-x,661,820;file-json-2,820,355;file-video,355,869;folder-cog,869,196;flame-kindling,49,967;figma,0,869;file-edit,49,869;file-lock,918,514;git-commit-horizontal,869,955;gamepad-2,710,967;eclipse,771,257;file-output,661,771;folder-pen,710,869;folder-clock,967,98;file-check-2,612,771;file-heart,0,918;folder-git,918,404;flask-conical-off,820,453;gift,820,955;file-plus,918,49;folder-down,147,918;fire-extinguisher,514,967;fullscreen,967,453;",
	[16898613777] = "square-arrow-out-up-right,967,514;table-cells-split,771,955;table-columns-split,967,808;square-asterisk,710,771;shield-ellipsis,771,306;squircle,820,759;sun-medium,661,967;sigma-square,869,514;square-stack,453,869;square-mouse-pointer,869,661;superscript,918,759;signal,918,0;square-gantt-chart,453,820;square-chevron-left,967,49;ship,771,98;stethoscope,147,967;square-m,306,967;square-arrow-up-right,820,661;signal-zero,514,869;square-minus,918,612;speech,820,147;sun-moon,967,196;sunset,967,710;shrub,306,820;table,820,955;spade,514,918;square-arrow-down,453,771;slack,0,918;sliders,404,771;shield-x,514,820;square-dashed-kanban,98,918;shield-off,820,514;stop-circle,453,918;shopping-basket,0,869;skip-back,147,771;swiss-franc,820,857;spell-check,196,771;siren,771,147;shield-alert,49,771;square-user-round,355,967;sunrise,453,967;strikethrough,869,759;sparkle,967,0;shirt,98,771;square-split-horizontal,918,404;sun-snow,196,967;smile-plus,918,514;star-off,612,967;square-dashed-bottom-code,196,820;shower-head,771,355;subscript,820,808;swords,967,759;ship-wheel,820,49;speaker,869,98;table-rows-split,869,906;square-chevron-down,514,967;sticky-note,918,453;shield-check,820,257;spell-check-2,771,196;sprout,918,306;square-x,918,661;step-forward,196,918;sticker,967,404;square-terminal,404,918;smile,869,563;signpost-big,869,49;square-percent,661,869;step-back,918,196;square-library,355,918;sheet,820,0;subtitles,771,857;signal-low,612,771;square-arrow-right,918,563;signpost,820,98;skip-forward,98,820;skull,49,869;split-square-vertical,49,918;snowflake,771,661;sliders-horizontal,820,355;square-dashed-bottom,147,869;tag,967,906;sun-dim,710,918;square-dashed-mouse-pointer,49,967;square-check,563,918;square-arrow-down-right,771,453;square-scissors,147,918;swatch-book,869,808;square,869,710;shell,771,49;square-chevron-up,869,147;square-arrow-left,404,820;split,0,967;square-kanban,404,869;square-sigma,98,967;star,967,147;square-pilcrow,563,967;square-arrow-up-left,869,612;shield-plus,771,563;sun,967,453;star-half,661,918;tablet,918,906;tags,918,955;square-check-big,612,869;table-properties,918,857;sparkles,918,49;stretch-vertical,918,710;sword,710,967;slice,869,306;settings,771,257;square-menu,967,563;square-arrow-up,771,710;spline,147,820;square-plus,918,147;shield,869,0;square-equal,869,404;square-chevron-right,918,98;tally-1,967,955;shopping-cart,869,257;split-square-horizontal,98,869;square-bottom-dashed-scissors,661,820;stamp,710,869;square-activity,869,355;shovel,820,306;share,514,771;square-arrow-out-down-right,306,918;square-radical,196,869;snail,820,612;square-parking,771,759;soup,612,820;square-pen,710,820;spray-can,967,257;store,404,967;slash,918,257;syringe,918,808;square-slash,967,355;settings-2,0,771;signal-high,771,612;sliders-vertical,771,404;table-2,869,857;square-parking-off,820,710;shield-question,563,771;square-power,869,196;square-user,967,612;tablets,869,955;signal-medium,563,820;square-divide,967,306;square-arrow-out-up-left,257,967;square-code,820,196;smartphone-nfc,306,869;square-split-vertical,869,453;squirrel,771,808;square-pi,612,918;square-arrow-down-left,820,404;share-2,771,514;shield-ban,0,820;shopping-bag,49,820;shuffle,257,869;switch-camera,771,906;space,563,869;square-arrow-out-down-left,355,869;shrink,355,771;sofa,661,771;square-dot,918,355;shield-minus,257,820;stretch-horizontal,967,661;smartphone,257,918;square-play,967,98;server,771,0;table-cells-merge,820,906;smartphone-charging,355,820;tablet-smartphone,967,857;sigma,820,563;shield-half,306,771;shapes,257,771;square-function,820,453;",
	[16898613044] = "dna-off,453,967;concierge-bell,869,147;cloud-download,612,820;cloud,918,306;citrus,306,820;circle-dot-dashed,771,514;copy,918,612;disc,661,967;delete,661,918;clipboard-pen-line,918,0;dices,918,710;circle-plus,869,0;disc-3,771,857;columns-4,710,771;compass,514,967;clipboard-copy,820,563;circle-chevron-up,771,0;clipboard-edit,771,612;cloud-sun,0,967;circle,771,355;dollar-sign,820,857;cloud-hail,967,0;copy-check,453,820;circle-power,820,49;command,563,918;circle-minus,771,306;copy-minus,404,869;clock-2,771,404;clock-7,918,514;circle-user-round,0,869;cog,918,563;dog,869,808;dot,918,808;clipboard-paste,514,869;circle-parking,820,514;database,710,869;clipboard-minus,563,820;cloud-upload,967,257;circle-stop,49,820;circle-parking-off,257,820;dice-1,147,967;circle-percent,563,771;container,967,306;corner-down-left,771,759;dribbble,918,857;columns,661,820;clock-12,820,355;codesandbox,257,967;club,771,453;diff,869,759;circle-slash,98,771;clipboard-pen,869,49;cloud-moon,820,147;donut,771,906;dna,967,710;creative-commons,147,918;clipboard-x,98,820;dice-2,967,404;door-closed,710,967;clock-10,918,257;drumstick,869,955;disc-2,820,808;clock-11,869,306;dice-4,453,918;clipboard-list,612,771;contact-round,98,918;contact-2,147,869;copy-x,967,563;clock,771,661;columns-3,771,710;cloud-rain,147,820;codepen,306,918;corner-right-down,563,967;cuboid,355,967;cloud-off,771,196;cloud-rain-wind,196,771;clipboard-type,147,771;ear,967,955;drum,918,906;dock,918,759;croissant,967,355;diameter,967,147;circle-dashed,0,771;code-xml,404,820;divide,967,453;circle-ellipsis,820,0;cloud-sun-rain,49,918;contact,49,967;circle-user,869,257;clipboard-check,869,514;cookie,869,404;clipboard,49,869;clock-3,404,771;cup-soda,967,612;cloud-drizzle,563,869;crown,404,918;circle-dot,514,771;cloudy,869,355;clover,820,404;code,355,869;coins,869,612;dumbbell,967,906;component,967,49;computer,918,98;construction,196,820;copy-slash,306,967;circle-play,514,820;clock-4,355,820;copyright,820,710;clock-1,0,918;crosshair,453,869;dice-3,918,453;dice-5,404,967;dice-6,967,661;download,820,906;drafting-compass,771,955;cone,820,196;clock-8,869,563;cloud-cog,661,771;droplet,820,955;circle-equal,771,49;copyleft,869,661;cpu,196,869;circle-gauge,0,820;cloud-snow,98,869;coffee,967,514;clipboard-plus,820,98;corner-down-right,710,820;circle-x,820,306;database-backup,820,759;corner-right-up,967,98;database-zap,771,808;droplets,967,857;download-cloud,869,857;circle-dollar-sign,257,771;diamond-percent,918,196;door-open,967,759;cloud-moon-rain,869,98;code-2,453,771;clock-5,306,869;circle-help,820,257;circle-fading-plus,49,771;drama,967,808;contrast,918,355;divide-circle,967,196;corner-left-down,661,869;cloud-lightning,918,49;circle-slash-2,771,98;credit-card,98,967;ear-off,918,955;circle-pause,771,563;clock-9,820,612;circle-off,306,771;dessert,612,967;cylinder,869,710;circle-divide,771,257;disc-album,710,918;clapperboard,257,869;cross,869,453;combine,612,869;currency,918,661;corner-left-up,612,918;drill,869,906;clipboard-signature,771,147;corner-up-left,918,147;clock-6,257,918;copy-plus,355,918;crop,918,404;columns-2,820,661;cloud-fog,514,918;corner-up-right,869,196;diamond,196,918;divide-square,196,967;cooking-pot,820,453;circuit-board,355,771;",
	[16898612629] = "bean,967,906;arrow-up-right-from-circle,563,967;align-horizontal-distribute-center,771,355;align-center,0,869;badge-swiss-franc,771,857;arrow-left-square,196,820;arrows-up-from-line,918,404;arrow-left-from-line,869,147;arrow-right-square,869,404;align-vertical-justify-center,49,869;arrow-big-up,918,306;alert-circle,869,0;badge-cent,612,967;bar-chart-horizontal,710,967;bean-off,869,955;battery-medium,869,906;arrow-up-left-square,710,820;badge-help,147,967;angry,257,918;armchair,820,147;badge-plus,918,710;align-horizontal-distribute-end,355,771;badge-russian-ruble,820,808;align-end-vertical,820,306;arrow-up-left,661,869;award,918,661;area-chart,869,98;archive-x,967,0;alarm-clock,257,820;arrow-up-from-line,820,710;arrow-big-down-dash,771,196;ampersands,355,820;app-window-mac,661,771;battery-full,967,808;badge-dollar-sign,918,196;align-start-vertical,820,98;audio-waveform,967,612;arrow-right,453,820;arrow-big-left,98,869;baby,771,808;badge-check,967,147;alarm-minus,820,514;arrow-right-circle,49,967;banknote,453,967;arrow-down,967,49;arrow-up-down,918,612;align-right,918,0;arrow-big-down,196,771;arrow-big-right,0,967;a-arrow-down,771,0;arrow-left,98,918;accessibility,257,771;arrow-up-narrow-wide,612,918;arrow-left-circle,918,98;baggage-claim,967,196;align-vertical-space-around,869,306;axis-3d,820,759;badge-pound-sterling,869,759;app-window,612,820;a-arrow-up,0,771;battery-low,918,857;air-vent,820,0;arrow-down-wide-narrow,563,918;activity-square,771,514;align-justify,563,820;bed-single,967,955;align-horizontal-space-around,771,612;battery-warning,820,955;arrow-down-from-line,404,820;alarm-clock-minus,820,257;align-horizontal-justify-center,257,869;antenna,869,563;align-center-vertical,49,820;align-end-horizontal,869,257;arrow-up-wide-narrow,147,918;align-vertical-space-between,820,355;arrow-down-z-a,514,967;bath,820,906;anvil,820,612;archive-restore,514,918;archive,918,49;arrow-big-left-dash,147,820;arrow-down-0-1,869,355;arrow-down-a-z,771,453;arrow-down-left,257,967;arrow-down-up,612,869;arrow-up-1-0,355,918;arrow-up-a-z,306,967;arrow-up,967,355;asterisk,869,453;audio-lines,355,967;ban,196,967;badge-euro,196,918;badge-info,918,453;badge,661,967;bar-chart-3,918,759;bar-chart,967,759;alert-octagon,820,49;align-vertical-distribute-start,98,820;alarm-plus,771,563;album,514,820;activity,514,771;axe,869,710;battery-charging,771,955;arrow-up-z-a,98,967;align-horizontal-justify-start,820,563;bar-chart-big,820,857;atom,404,918;bed-double,918,955;arrow-down-narrow-wide,967,514;alert-triangle,771,98;align-horizontal-distribute-start,306,820;arrow-down-to-line,661,820;arrow-down-square,771,710;banana,967,453;arrow-right-left,918,355;bar-chart-4,869,808;arrow-big-right-dash,49,918;backpack,710,869;arrow-down-right,820,661;align-vertical-distribute-center,771,147;ampersand,404,771;align-vertical-justify-end,0,918;alarm-smoke,563,771;battery,967,857;arrow-up-right,918,147;at-sign,453,869;arrow-down-right-from-circle,918,563;apple,563,869;arrow-up-0-1,404,869;arrow-big-up-dash,967,257;bar-chart-2,967,710;arrow-left-to-line,147,869;align-horizontal-justify-end,869,514;align-vertical-distribute-end,147,771;airplay,771,49;aperture,771,661;align-horizontal-space-between,612,771;alarm-clock-plus,306,771;arrow-up-square,869,196;arrow-down-left-square,306,918;alarm-clock-check,0,820;anchor,306,869;arrow-right-to-line,820,453;arrow-down-circle,453,771;a-large-small,771,257;arrow-right-from-line,967,306;baseline,869,857;ambulance,771,404;arrow-down-right-square,869,612;badge-japanese-yen,453,918;align-center-horizontal,98,771;badge-alert,661,918;arrow-down-left-from-circle,355,869;alarm-check,49,771;arrow-up-from-dot,869,661;align-vertical-justify-start,918,257;barcode,918,808;arrow-up-to-line,196,869;badge-percent,967,661;align-left,514,869;arrow-up-circle,967,563;bar-chart-horizontal-big,771,906;badge-minus,404,967;badge-indian-rupee,967,404;align-start-horizontal,869,49;arrow-down-to-dot,710,771;badge-x,710,918;alarm-clock-off,771,306;arrow-down-1-0,820,404;arrow-left-right,820,196;beaker,918,906;annoyed,918,514;arrow-up-left-from-circle,771,759;arrow-up-right-square,967,98;",
	[16898612819] = "bolt,306,820;between-horizontal-end,771,306;bus-front,869,612;between-vertical-end,257,820;chevron-up-circle,820,808;chevrons-up-down,918,759;book-up-2,306,869;chevrons-up,869,808;chevron-right-square,918,710;calendar-clock,918,98;captions-off,661,869;check-square-2,820,759;book-plus,771,404;cake-slice,661,820;calendar,355,918;book-user,918,514;cctv,355,967;circle-arrow-out-down-left,771,955;book-a,820,563;chrome,820,857;check-square,771,808;chevron-left-square,453,918;circle-arrow-up,967,857;boxes,196,771;chevron-up,710,918;blocks,49,820;calendar-days,869,147;bookmark-plus,612,820;chevrons-down,967,196;bluetooth-off,869,257;cannabis,710,820;book,820,612;calendar-minus-2,147,869;book-image,771,147;brackets,98,869;calendar-heart,196,820;calendar-fold,820,196;cigarette,967,759;chevron-right-circle,967,661;bot,869,98;chevron-down-square,918,196;book-heart,820,98;circle-chevron-right,967,955;between-vertical-start,820,514;bug,257,967;circle-chevron-left,918,955;calendar-x-2,453,820;box-select,820,147;circle-arrow-out-down-right,967,808;beef,0,771;car-taxi-front,967,98;calendar-x,404,869;circle-check-big,918,906;book-dashed,514,869;check-circle-2,918,661;bike,771,563;camera-off,306,967;brain-cog,0,967;bookmark-check,771,661;chevrons-left-right,196,967;book-audio,771,612;cassette-tape,918,404;bold,355,771;beer,257,771;chef-hat,661,918;bird,869,0;bluetooth-connected,0,869;chevron-left,404,967;book-open-check,918,257;bus,820,661;biohazard,514,820;book-up,257,918;chevron-down-circle,967,147;calendar-plus,918,355;bell-electric,514,771;book-key,147,771;circle-arrow-right,820,955;building-2,967,514;cake,612,869;bell,820,257;brick-wall,918,306;briefcase-medical,820,404;bell-off,771,49;binary,563,771;book-open-text,869,306;calculator,563,918;bluetooth,771,355;castle,453,869;book-down,918,0;book-headphones,869,49;book-marked,49,869;book-open,820,355;book-text,404,771;book-type,355,820;check-check,967,612;book-x,869,563;bookmark,514,918;brain-circuit,49,918;briefcase-business,869,355;bug-play,306,918;brush,404,820;cable-car,771,710;cable,710,771;calendar-check,967,49;calendar-minus,98,918;calendar-plus-2,967,306;calendar-search,820,453;circle-chevron-down,967,906;building,918,563;caravan,869,196;carrot,196,869;cherry,612,967;bell-minus,820,0;case-sensitive,98,967;case-lower,147,918;chevron-last,967,404;chevron-up-square,771,857;chevrons-left,967,453;chevrons-right-left,453,967;car,918,147;circle-arrow-left,820,906;circle-arrow-out-up-left,918,857;case-upper,967,355;circle-arrow-out-up-right,869,906;circle-check,869,955;bomb,257,869;calendar-range,869,404;chevron-down,196,918;calendar-check-2,514,967;bitcoin,820,49;braces,147,820;blend,771,98;bug-off,355,869;candy-off,820,710;cigarette-off,710,967;beer-off,771,257;chevrons-down-up,661,967;chevrons-right,967,710;circle-arrow-down,869,857;calendar-off,49,967;check,710,869;boom-box,967,0;brain,967,257;book-copy,563,820;car-front,563,967;circle-alert,918,808;briefcase,771,453;bring-to-front,453,771;bell-plus,49,771;chevron-left-circle,918,453;book-check,612,771;book-lock,98,820;candy,771,759;bookmark-x,563,869;candy-cane,869,661;captions,612,918;chevron-right,869,759;cast,869,453;bed,771,0;camera,967,563;bluetooth-searching,820,306;box,771,196;cat,404,918;candlestick-chart,918,612;book-minus,0,918;check-circle,869,710;bone,869,514;chevron-first,147,967;bell-dot,771,514;church,771,906;blinds,98,771;bot-message-square,918,49;bookmark-minus,661,771;bell-ring,0,820;between-horizontal-start,306,771;",
	[16898613509] = "grip-vertical,0,869;globe-lock,820,514;grab,514,820;heading-3,869,306;hard-drive-download,918,0;ligature,612,967;iteration-cw,869,147;hexagon,967,0;inspection-panel,563,918;hard-drive,820,98;heart-handshake,869,563;ham,355,771;hotel,98,869;ice-cream,869,355;lightbulb,918,196;git-graph,0,771;goal,563,771;haze,98,820;indian-rupee,710,771;loader-2,820,857;lamp-desk,355,918;instagram,514,967;grid-2x2,771,98;gitlab,820,257;list-minus,820,808;history,869,98;lamp-ceiling,404,869;hourglass,49,918;keyboard,453,820;layers-2,196,869;hammer,306,820;list-ordered,710,918;help-circle,563,869;leaf,918,661;hop,196,771;git-pull-request-closed,771,514;kanban-square,98,918;heading-4,820,355;git-pull-request-create,820,0;layout-grid,918,404;log-out,820,955;list-checks,404,967;infinity,661,820;image-minus,771,453;github,0,820;hand-metal,771,612;ice-cream-cone,918,306;layout-panel-left,453,869;italic,967,49;import,967,514;laugh,869,196;japanese-yen,820,196;library,710,869;lamp-wall-up,918,612;images,257,967;lollipop,967,857;lamp-floor,306,967;image,306,918;group,820,306;hand-platter,612,771;indent,771,710;mail-minus,967,955;home,820,147;list,869,808;list-restart,967,196;mail-check,918,955;list-todo,967,453;globe-2,257,820;landmark,771,759;loader,710,967;layout-template,355,967;hand-heart,869,514;key,869,404;lasso-select,967,98;log-in,869,906;locate-fixed,967,759;hard-hat,771,147;heading-6,404,771;hand-coins,257,869;joystick,196,820;library-big,820,759;heart,661,771;glass-water,771,306;glasses,306,771;linkedin,453,918;life-buoy,661,918;hash,147,771;image-up,355,869;keyboard-music,820,453;lock,918,857;hdmi-port,49,869;grape,820,49;layout-panel-top,404,918;laptop-minimal,612,918;layout,967,612;indent-decrease,869,612;heart-off,820,612;laptop-2,661,869;land-plot,820,710;git-pull-request-draft,771,49;ice-cream-bowl,967,257;grip-horizontal,49,820;laptop,563,967;git-pull-request-create-arrow,514,771;list-video,967,710;loader-circle,771,906;image-off,453,771;line-chart,196,918;list-tree,453,967;heater,612,820;lamp,869,661;link-2-off,147,967;leafy-green,869,710;git-fork,771,0;hospital,147,820;git-merge,771,257;globe,771,563;kanban,49,967;graduation-cap,869,0;hand-helping,820,563;hand,563,820;heading-2,918,257;headset,257,918;heart-crack,918,514;grip,869,257;image-down,820,404;lock-keyhole-open,820,906;list-end,918,710;lamp-wall-down,967,563;link-2,967,404;lasso,918,147;layout-dashboard,967,355;heading-1,0,918;library-square,771,808;heart-pulse,771,661;list-filter,869,759;list-music,771,857;list-plus,661,967;list-collapse,967,661;locate-off,918,808;locate,869,857;lock-keyhole,771,955;lock-open,967,808;m-square,869,955;magnet,967,906;image-plus,404,820;info,612,869;ice-cream-2,0,967;inbox,918,563;layout-list,869,453;heading-5,771,404;languages,710,820;guitar,771,355;heading,355,820;key-square,918,355;list-start,196,967;hard-drive-upload,869,49;hop-off,771,196;iteration-ccw,918,98;layers-3,147,918;kanban-square-dashed,147,869;layers,98,967;indent-increase,820,661;link,918,453;git-pull-request,49,771;key-round,967,306;headphones,306,869;highlighter,918,49;handshake,514,869;list-x,918,759;git-pull-request-arrow,257,771;helping-hand,514,918;luggage,918,906;lightbulb-off,967,147;grid-3x3,98,771;",
	[16898613869] = "toggle-left,869,49;video,355,967;wifi-off,918,759;ungroup,257,967;unlock,771,710;ticket-percent,257,869;x,869,906;voicemail,869,710;tree-palm,820,612;theater,98,771;tent,49,771;volume-x,710,869;unplug,710,771;trello,612,820;torus,147,771;trees,661,771;text,771,98;user-round-check,869,404;trending-down,563,869;videotape,967,612;utensils-crossed,918,147;underline,820,404;view,918,661;volume,661,918;user-x-2,771,759;train-front-tunnel,771,404;unfold-horizontal,355,869;users-2,612,918;vegan,967,355;terminal-square,0,820;wifi,869,808;wrap-text,869,857;trophy,820,147;umbrella,869,355;touchpad,49,869;worm,918,808;zap,918,906;washing-machine,918,710;user-search,918,612;upload,612,869;triangle,869,98;user-minus,49,967;x-octagon,967,808;wand,404,967;tree-deciduous,869,563;user-2,514,967;test-tube-2,771,306;ticket-slash,820,563;trash-2,257,918;volume-1,820,759;timer,918,0;watch,869,759;whole-word,967,710;user-plus,918,355;tram-front,306,869;toy-brick,918,257;x-circle,771,955;waypoints,771,857;text-quote,514,820;wind,820,857;vault,98,967;timer-reset,514,869;x-square,918,857;video-off,404,918;tally-2,771,0;unfold-vertical,306,918;tree-pine,771,661;toggle-right,820,98;tent-tree,771,49;twitch,49,918;user,661,869;test-tubes,820,514;wheat,453,967;tangent,771,514;vibrate-off,869,453;wine,710,967;utensils,869,196;ticket-plus,869,514;user-cog,147,869;unlink-2,918,563;wrench,820,906;user-check,918,98;webhook-off,661,967;thermometer-sun,0,869;test-tube-diagonal,306,771;twitter,0,967;telescope,820,0;zoom-in,869,955;tally-3,0,771;tally-5,257,771;user-square-2,869,661;volume-2,771,808;user-check-2,967,49;text-select,820,49;ticket-check,355,771;user-cog-2,196,820;user-round,967,563;trash,918,514;upload-cloud,661,820;user-circle-2,869,147;truck,771,196;zap-off,967,857;vibrate,453,869;wallet-2,967,147;text-cursor-input,771,563;user-x,710,820;weight,196,967;wallet,147,967;unlock-keyhole,820,661;venetian-mask,918,404;timer-off,563,820;youtube,820,955;wand-sparkles,453,918;university,967,514;user-plus-2,967,306;thumbs-down,820,306;thumbs-up,771,355;thermometer-snowflake,49,820;wine-off,771,906;undo-2,771,453;wallet-cards,918,196;ticket,612,771;train-front,404,771;utility-pole,196,869;ticket-x,771,612;user-round-plus,404,869;user-round-minus,453,820;text-search,869,0;traffic-cone,820,355;wheat-off,967,453;usb,563,918;undo,404,820;thermometer,869,257;touchpad-off,98,820;user-round-cog,820,453;text-cursor,563,771;ticket-minus,306,820;tally-4,771,257;wallpaper,967,404;zoom-out,967,906;tractor,869,306;waves,820,808;vote,612,967;workflow,967,759;undo-dot,453,771;target,514,771;warehouse,967,661;trending-up,514,918;unlink,869,612;user-round-search,355,918;wallet-minimal,196,918;umbrella-off,918,306;tv-2,147,820;triangle-right,918,49;type,967,257;webhook,967,196;turtle,196,771;user-minus-2,98,918;tv,98,869;user-round-x,306,967;tornado,771,147;triangle-alert,967,0;wand-2,918,453;users-round,563,967;webcam,710,918;user-square,820,710;train-track,355,820;terminal,820,257;tower-control,0,918;users,967,98;test-tube,257,820;user-circle,820,196;variable,147,918;",
	[16898613613] = "messages-square,306,869;parentheses,869,906;navigation-2-off,918,612;mouse-pointer-click,771,710;package-minus,771,808;mouse-pointer-square-dashed,710,771;monitor-check,196,771;paintbrush-2,967,404;panel-right-close,453,967;nut-off,98,967;menu,49,820;outdent,918,661;nfc,612,918;notebook-tabs,967,98;panels-left-bottom,820,906;minus-circle,869,98;navigation-2,869,661;message-square-heart,771,147;monitor-dot,147,820;newspaper,661,869;move-vertical,820,453;more-horizontal,257,967;octagon-alert,918,404;panel-bottom-dashed,918,710;panel-left-dashed,661,967;message-circle-warning,771,612;map,306,771;message-square-plus,49,869;music-4,306,967;message-circle-plus,257,869;nut,967,355;message-square-dashed,918,0;move-left,98,918;mic,820,612;message-square-quote,0,918;moon-star,355,869;move-up,869,404;mic-off,918,514;paperclip,918,857;minus,771,196;move-down,196,820;panel-right-dashed,967,710;panel-right,820,857;monitor,404,820;move-diagonal-2,967,49;panel-top-dashed,710,967;megaphone-off,514,820;minus-square,820,147;parking-circle-off,820,955;monitor-stop,820,404;navigation-off,820,710;megaphone,869,0;map-pinned,771,306;package-search,612,967;option,355,967;message-circle-question,869,514;mail,820,0;package-2,869,710;move-down-right,820,196;parking-square-off,869,955;notepad-text,147,918;panel-top-inactive,967,759;monitor-down,98,869;map-pin,820,257;move-diagonal,918,98;panel-bottom-close,967,661;mic-vocal,869,563;monitor-pause,0,967;music-2,404,869;mail-x,514,771;move-down-left,869,147;orbit,967,612;memory-stick,771,98;message-square-off,98,820;parking-circle,967,857;menu-square,98,771;message-circle-code,869,257;package-open,710,869;move-up-left,967,306;panel-bottom-inactive,869,759;message-square-x,404,771;paint-roller,147,967;medal,563,771;maximize-2,820,514;network,710,820;mouse-pointer,612,869;mailbox,771,49;message-square-diff,869,49;moon,306,918;monitor-smartphone,918,306;move-3d,514,967;mouse,563,918;mails,49,771;party-popper,918,955;message-square-more,147,771;move-horizontal,147,869;move-up-right,918,355;milk,514,918;package-x,967,147;message-square-code,514,869;panel-top-open,918,808;notebook,869,196;mouse-pointer-2,820,661;message-circle-more,355,771;navigation,771,759;panel-top,869,857;message-square-dot,820,98;minimize-2,967,0;palette,453,918;merge,0,869;palmtree,404,967;message-circle,563,820;monitor-speaker,869,355;monitor-up,771,453;message-square-reply,918,257;paint-bucket,196,918;monitor-x,453,771;octagon-pause,869,453;octagon,404,918;message-square,355,820;notebook-pen,563,967;panel-left-close,710,918;message-square-text,820,355;mail-plus,0,771;mail-search,257,771;move,453,820;map-pin-off,0,820;message-circle-heart,771,355;message-circle-dashed,820,306;maximize,771,563;message-circle-off,306,820;minimize,918,49;microwave,661,771;octagon-x,453,869;notebook-text,918,147;monitor-play,967,257;monitor-off,49,918;panel-left-inactive,967,196;notepad-text-dashed,196,869;more-vertical,967,514;move-right,49,967;meh,820,49;mail-warning,771,514;music-3,355,918;pause-circle,967,955;panels-right-bottom,771,955;martini,257,820;panel-right-inactive,918,759;package-plus,661,918;mic-2,257,918;paintbrush,918,453;panel-bottom,771,857;panel-bottom-open,820,808;panel-top-close,771,906;parking-meter,918,906;parking-square,967,906;mountain,869,612;message-circle-reply,820,563;panel-right-open,869,808;microscope,771,661;message-circle-x,612,771;music,967,563;mouse-pointer-square,661,820;milestone,612,820;milk-off,563,869;package-check,820,759;panel-left-open,196,967;mail-question,771,257;message-square-warning,771,404;package,918,196;mountain-snow,918,563;panel-left,967,453;panels-top-left,967,808;message-square-share,869,306;mail-open,771,0;",
}
local ICON, ALIAS = {}, {house = "home", ["check-circle"] = "circle-check", ["alert-triangle"] = "triangle-alert", ["x-circle"] = "circle-x", ["alert-circle"] = "circle-alert"}
for id, s in pairs(SHEETS) do
	for nm, x, y in s:gmatch("([%w%-]+),(%d+),(%d+);") do ICON[nm] = {id, tonumber(x), tonumber(y)} end
end
SHEETS = nil
function Lib:RegisterIcon(name, v) Lib.Icons[tostring(name):lower()] = v end -- v: "rbxassetid://..." or {Image=, Offset=Vector2, Size=Vector2}

-- Themes: a theme is a table of colors (hex or Color3); unspecified keys fall back to Dark ------------------------
function Lib:AddTheme(n, c)
	for k, v in pairs(c) do if type(v) == "string" then c[k] = Color3.fromHex(v) end end
	Lib.Themes[n] = Lib.Themes.Dark and setmetatable(c, {__index = Lib.Themes.Dark}) or c
end
Lib:AddTheme("Dark", {Bg = "0b0b0c", Card = "121214", Raised = "1c1c1f", Field = "0f0f11", Line = "222225", Border = "313136", Text = "f4f4f5", Sub = "9a9aa2",
	Muted = "6b6b72", Accent = "f4f4f5", OnAccent = "0b0b0c", Track = "2c2c31", Success = "3ecf8e", Warning = "f5a623", Danger = "ef4444"})
Lib:AddTheme("Light", {Bg = "ffffff", Card = "f8f8f9", Raised = "ffffff", Field = "f4f4f5", Line = "e8e8ea", Border = "d4d4d8", Text = "0b0b0c", Sub = "62626a",
	Muted = "9a9aa2", Accent = "0b0b0c", OnAccent = "ffffff", Track = "dcdce0"})
Lib:AddTheme("Midnight", {Bg = "0a0d14", Card = "0e1320", Raised = "182033", Field = "0b0f19", Line = "1a2233", Border = "26314a", Text = "e6ecff", Sub = "8794b3",
	Muted = "5d6a8c", Accent = "7c9cff", OnAccent = "0a0d14", Track = "26314a"})
Lib.Theme, Lib.ThemeName = Lib.Themes.Dark, "Dark"

-- Core helpers -------------------------------------------------------------------------------------------------------
local bound, active, n = {}, {}, 0
local function nx() n = n + 1 return n end
local function mix(a, b) for k, v in pairs(b or {}) do a[k] = v end return a end
local function px(v) return math.floor(v + .5) end -- whole pixels keep text sharp
local function tw(o, p, t, s, d)
	local tween = TS:Create(o, TweenInfo.new(t or .15, s or Enum.EasingStyle.Quad, d or Enum.EasingDirection.Out), p)
	tween:Play()
	return tween
end
local function apply(o, p, now) if now then mix(o, p) else tw(o, p) end end -- set properties instantly (now) or tween them
local function on(s, f) table.insert(Lib.Conns, s:Connect(f)) end
local function prune() for i = #bound, 1, -1 do if not bound[i][1].Parent then table.remove(bound, i) end end end
local function viewport() return workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or V2(1280, 720) end

-- Binds a property to a theme key (string) or function(theme); returns an updater that tweens to the current value.
local function reg(o, p, f)
	if type(f) == "string" then local k = f; f = function(t) return t[k] end end
	bound[#bound + 1] = {o, p, f}
	o[p] = f(Lib.Theme)
	return function() tw(o, {[p] = f(Lib.Theme)}) end
end

-- Instance builder. Special keys: T = {Prop = themeKey|fn}, R = corner, S = themed stroke, P = padding, L = list layout.
local function new(class, p, kids)
	local o, ups = Instance.new(class), {}
	p = p or {}
	if o:IsA("GuiObject") then o.BorderSizePixel, o.BackgroundTransparency = 0, 1 end
	if o:IsA("GuiButton") then o.AutoButtonColor = false end
	if o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox") then -- empty text by default (no stray "TextBox"/"Button" captions)
		o.Text, o.FontFace, o.TextSize, o.TextXAlignment = "", Lib.Font(), 14, Enum.TextXAlignment.Left
	end
	local T, R, S, P, L = p.T, p.R, p.S, p.P, p.L
	p.T, p.R, p.S, p.P, p.L = nil, nil, nil, nil, nil
	for k, v in pairs(p) do o[k] = v end
	for k, v in pairs(T or {}) do ups[#ups + 1] = reg(o, k, v) end
	if R then new("UICorner", {CornerRadius = UDim.new(0, R), Parent = o}) end
	if S then ups[#ups + 1] = reg(new("UIStroke", {Parent = o, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}), "Color", S) end
	if P then
		local q = type(P) == "number" and {P, P, P, P} or P
		new("UIPadding", {Parent = o, PaddingTop = UDim.new(0, q[1]), PaddingRight = UDim.new(0, q[2]), PaddingBottom = UDim.new(0, q[3]), PaddingLeft = UDim.new(0, q[4])})
	end
	if L then
		L = type(L) == "number" and {L} or L
		local h = L[2] == "H"
		new("UIListLayout", {Parent = o, Padding = UDim.new(0, L[1]), SortOrder = Enum.SortOrder.LayoutOrder,
			FillDirection = h and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
			VerticalAlignment = h and Enum.VerticalAlignment.Center or Enum.VerticalAlignment.Top})
	end
	return o, function() for _, u in ipairs(ups) do u() end end
end

local function label(p, text, size, color, weight, props)
	return new("TextLabel", mix({Parent = p, Text = text, TextSize = size, FontFace = Lib.Font(weight), T = {TextColor3 = color}}, props))
end
local function line(p, props) return new("Frame", mix({Parent = p, Size = U(1, 0, 0, 1), BackgroundTransparency = 0, T = {BackgroundColor3 = "Line"}}, props)) end
local function dot(p, f, props) return new("Frame", mix({Parent = p, Size = O(6, 6), BackgroundTransparency = 0, R = 3, T = {BackgroundColor3 = f}}, props)) end

-- Fades a whole subtree without CanvasGroup (CanvasGroups re-rasterize their children and make text soft). hide: tween to
-- invisible, otherwise back to the transparencies captured the first time; now = apply instantly.
local base = setmetatable({}, {__mode = "k"})
local function fade(root, hide, t, now)
	local function go(d)
		local ps = base[d]
		if not ps then
			ps = {}
			if d:IsA("GuiObject") then ps.BackgroundTransparency = d.BackgroundTransparency end
			if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then ps.TextTransparency = d.TextTransparency end
			if d:IsA("ImageLabel") or d:IsA("ImageButton") then ps.ImageTransparency = d.ImageTransparency end
			if d:IsA("UIStroke") then ps.Transparency = d.Transparency end
			base[d] = ps
		end
		local goal = {}
		for k, v in pairs(ps) do goal[k] = hide and 1 or v end
		if next(goal) then apply(d, goal, now) end
	end
	go(root)
	for _, d in ipairs(root:GetDescendants()) do go(d) end
end

-- Icons: Lucide name (or alias / registered name / rbxassetid string) -> sprite on an ImageLabel
local function sprite(img, name)
	name = tostring(name or ""):lower()
	local c = Lib.Icons[name]
	if type(c) == "table" then img.Image, img.ImageRectOffset, img.ImageRectSize = c.Image, c.Offset or V2(), c.Size or V2() return end
	if type(c) == "string" or name:sub(1, 13) == "rbxassetid://" then img.Image, img.ImageRectOffset, img.ImageRectSize = c or name, V2(), V2() return end
	local d = ICON[name] or ICON[ALIAS[name] or ""]
	if d then img.Image, img.ImageRectSize, img.ImageRectOffset = "rbxassetid://" .. d[1], V2(48, 48), V2(d[2], d[3]) else img.Image = "" end
end
local function icon(p, name, props) -- 16px by default: an exact 3:1 reduction of the 48px sprite
	local img, up = new("ImageLabel", mix({Parent = p, Size = O(16, 16)}, props))
	sprite(img, name)
	return img, up
end
function Lib:Icon(name, parent, props) return icon(parent, name, props) end

-- Pointer tracking: f() runs on press and returns move(delta, position); used for dragging, resizing and sliders.
local function track(h, f)
	h.InputBegan:Connect(function(i)
		local t, s = i.UserInputType, i.Position
		if t ~= Enum.UserInputType.MouseButton1 and t ~= Enum.UserInputType.Touch then return end
		local move, c, e = f()
		move(Vector3.zero, s)
		c = UIS.InputChanged:Connect(function(m)
			if m.UserInputType == Enum.UserInputType.MouseMovement or m.UserInputType == Enum.UserInputType.Touch then move(m.Position - s, m.Position) end
		end)
		e = UIS.InputEnded:Connect(function(x) if x.UserInputType == t then c:Disconnect() e:Disconnect() end end)
	end)
end
local function drag(h, main)
	track(h, function() local p = main.Position
		return function(d) main.Position = U(p.X.Scale, px(p.X.Offset + d.X), p.Y.Scale, px(p.Y.Offset + d.Y)) end end)
end

-- Pointer area over frame h: f(x, y) receives the pointer position normalised to 0-1; pad enlarges the hit zone vertically.
local function area(h, f, pad)
	pad = pad or 0
	local hit = new("TextButton", {Parent = h, Position = U(0, 0, 0, -pad / 2), Size = U(1, 0, 1, pad), ZIndex = 5})
	track(hit, function()
		return function(_, pos)
			f(math.clamp((pos.X - h.AbsolutePosition.X) / h.AbsoluteSize.X, 0, 1), math.clamp((pos.Y - h.AbsolutePosition.Y) / h.AbsoluteSize.Y, 0, 1))
		end
	end)
end

-- Small widgets -------------------------------------------------------------------------------------------------------
local function knob(p) -- ring handle used by the color picker
	local k = new("Frame", {Parent = p, AnchorPoint = V2(.5, .5), Size = O(14, 14), BackgroundTransparency = 0, R = 7})
	new("UIStroke", {Parent = k, Color = Color3.new(1, 1, 1), Thickness = 2})
	return k
end

local function tick(p, boxed) -- check mark (optionally inside a checkbox) on the right of p; returns paint(on, instant)
	local f = new("Frame", {Parent = p, AnchorPoint = V2(1, .5), Position = U(1, -10, .5, 0), Size = O(16, 16), R = 4, S = boxed and "Border" or nil, T = {BackgroundColor3 = "Accent"}})
	local i = icon(f, "check", {AnchorPoint = V2(.5, .5), Position = Sc(.5, .5), Size = boxed and O(12, 12) or O(16, 16), T = {ImageColor3 = boxed and "OnAccent" or "Text"}})
	return function(state, now)
		if boxed then apply(f, {BackgroundTransparency = state and 0 or 1}, now) end
		apply(i, {ImageTransparency = state and 0 or 1}, now)
	end
end

local function field(p, w) -- select-style button: text on the left, up/down chevrons on the right; returns button, label
	local b = new("TextButton", {Parent = p, Size = O(w or 160, 32), BackgroundTransparency = 0, R = 8, S = "Border", T = {BackgroundColor3 = "Raised"}})
	local s = b:FindFirstChildOfClass("UIStroke")
	local t = label(b, "", 13, "Text", nil, {Position = O(12, 0), Size = U(1, -40, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd})
	icon(b, "chevrons-up-down", {AnchorPoint = V2(1, .5), Position = U(1, -8, .5, 0), T = {ImageColor3 = "Muted"}})
	b.MouseEnter:Connect(function() tw(s, {Color = Lib.Theme.Sub}) end)
	b.MouseLeave:Connect(function() tw(s, {Color = Lib.Theme.Border}) end)
	return b, t
end

local function search(p, placeholder, fill, props) -- search field with a Lucide magnifier; returns frame, textbox
	local f = new("Frame", mix({Parent = p, BackgroundTransparency = 0, R = 8, S = "Border", T = {BackgroundColor3 = fill}}, props))
	local stroke = f:FindFirstChildOfClass("UIStroke")
	icon(f, "search", {AnchorPoint = V2(0, .5), Position = U(0, 10, .5, 0), T = {ImageColor3 = "Muted"}})
	local box = new("TextBox", {Parent = f, Position = O(34, 0), Size = U(1, -44, 1, 0), ClearTextOnFocus = false, PlaceholderText = placeholder, ClipsDescendants = true,
		T = {TextColor3 = "Text", PlaceholderColor3 = "Muted"}})
	box.Focused:Connect(function() tw(stroke, {Color = Lib.Theme.Sub}) end)
	box.FocusLost:Connect(function() tw(stroke, {Color = Lib.Theme.Border}) end)
	return f, box
end

local function measure(text, size, width, weight) -- wrapped text height in pixels
	local p = Instance.new("GetTextBoundsParams")
	p.Text, p.Font, p.Size, p.Width = text, Lib.Font(weight), size, width
	local ok, b = pcall(TXT.GetTextBoundsAsync, TXT, p)
	return ok and math.ceil(b.Y) or (size + 4) * math.max(1, math.ceil(#text * size * .55 / width))
end

-- Colors are stored as "rrggbb" (or "rrggbbaa" when the picker has Alpha) so they survive JSON configs.
local function toHex(c, a) return a and (c:ToHex() .. string.format("%02x", math.floor(a * 255 + .5))) or c:ToHex() end
local function fromHex(x)
	local s = tostring(x):gsub("[#%s]", "")
	local ok, c = pcall(Color3.fromHex, s:sub(1, 6))
	local a = tonumber(s:sub(7, 8), 16)
	return ok and c or Color3.new(1, 1, 1), a and a / 255 or 1
end
function Lib:GetColor(f) return fromHex(Lib.Flags[f] or "ffffff") end -- returns Color3, alpha

-- Persistence: every element writes to Lib.Flags and schedules a debounced save --------------------------------------
local function write(f, d) pcall(function() if not isfolder(Lib.Folder) then makefolder(Lib.Folder) end writefile(Lib.Folder .. "/" .. f, d) end) end
local function read(f) local ok, d = pcall(readfile, Lib.Folder .. "/" .. f) return ok and d or nil end
local function decode(c) local ok, d = pcall(function() return HS:JSONDecode(read(c .. ".json")) end) return ok and d or nil end
local pending
local function save()
	if pending then return end
	pending = task.delay(.5, function() pending = nil; Lib:Save() end)
end
function Lib:Save(c) Lib.Config = c or Lib.Config; write(Lib.Config .. ".json", HS:JSONEncode(mix(table.clone(Lib.Saved), Lib.Flags))) end
function Lib:Load(c)
	local d = decode(c); if not d then return false end
	Lib.Config, Lib.Saved = c, d
	for k, v in pairs(d) do if Lib.Setters[k] then Lib.Setters[k](v) end end
	if d.__theme then Lib:SetTheme(d.__theme) end
	return true
end
function Lib:Delete(c) pcall(delfile, Lib.Folder .. "/" .. c .. ".json") end
function Lib:List()
	local r = {}
	pcall(function() for _, f in ipairs(listfiles(Lib.Folder)) do local m = f:match("([^/\\]+)%.json$"); if m then r[#r + 1] = m end end end)
	return r
end

function Lib:SetTheme(t)
	local th = Lib.Themes[t]; if not th then return end
	Lib.Theme, Lib.ThemeName, Lib.Flags.__theme = th, t, t
	for i = #bound, 1, -1 do
		local b = bound[i]
		if b[1].Parent then tw(b[1], {[b[2]] = b[3](th)}, .25) else table.remove(bound, i) end
	end
	save()
end
function Lib:SetColor(k, c) Lib.Theme[k] = c; Lib:SetTheme(Lib.ThemeName) end
function Lib:Destroy()
	for _, c in ipairs(Lib.Conns) do c:Disconnect() end
	for _, g in ipairs(Lib.Guis) do g:Destroy() end
	Lib.Conns, Lib.Guis = {}, {}; table.clear(bound); table.clear(active)
end

-- bind: shared element plumbing. view(v) updates visuals; the returned set(v) also stores, saves and fires Callback.
local function bind(o, default, view)
	local flag = o.Flag; if flag == nil then flag = o.Name end
	local function set(v)
		view(v)
		if flag then Lib.Flags[flag] = v; save() end
		if o.Callback and v ~= nil then task.spawn(o.Callback, v) end
	end
	local v; if flag then Lib.Setters[flag] = set; v = Lib.Saved[flag] end
	if v == nil then v = default end
	set(v)
	return set
end

-- Keybind chip (used by Toggle{Keybind=} and Keybind elements). Saved as "<flag>_key".
local function chip(p, flag, default, press)
	local kf, key, listening = tostring(flag) .. "_key"
	local b = new("TextButton", {Parent = p, LayoutOrder = 1, AutomaticSize = AX, Size = O(0, 24), BackgroundTransparency = 0, R = 6, S = "Border", P = {0, 10, 0, 10},
		FontFace = Lib.Mono, TextSize = 12, TextXAlignment = CEN, T = {BackgroundColor3 = "Raised", TextColor3 = "Sub"}})
	new("UISizeConstraint", {Parent = b, MinSize = V2(28, 0)})
	local function set(k) key = k and Enum.KeyCode[k]; b.Text = k or "None"; Lib.Flags[kf] = k or false; save() end
	Lib.Setters[kf] = set
	local k = Lib.Saved[kf]; if k == nil and typeof(default) == "EnumItem" then k = default.Name end
	set(k or nil)
	b.Activated:Connect(function() listening, Lib.Listening, b.Text = true, true, "..." end)
	on(UIS.InputBegan, function(i, gp)
		if listening then
			if i.UserInputType ~= Enum.UserInputType.Keyboard then return end
			listening = false
			set(i.KeyCode ~= Enum.KeyCode.Escape and i.KeyCode.Name or nil)
			task.defer(function() Lib.Listening = nil end)
		elseif not gp and not Lib.Listening and key and i.KeyCode == key then press() end
	end)
end

-- Window chrome ------------------------------------------------------------------------------------------------------
local function controls(p, onMin, onClose)
	local box = new("Frame", {Parent = p, AnchorPoint = V2(1, .5), Position = U(1, -16, .5, 0), Size = O(60, 28), L = {4, "H"}})
	for i, d in ipairs{{f = onMin, i = "minus"}, {f = onClose, i = "x"}} do
		local b = new("TextButton", {Parent = box, Size = O(28, 28), LayoutOrder = i, R = 7, T = {BackgroundColor3 = "Raised"}})
		local ic = icon(b, d.i, {AnchorPoint = V2(.5, .5), Position = Sc(.5, .5), T = {ImageColor3 = "Sub"}})
		b.Activated:Connect(d.f)
		b.MouseEnter:Connect(function() tw(b, {BackgroundTransparency = 0}); tw(ic, {ImageColor3 = Lib.Theme.Text}) end)
		b.MouseLeave:Connect(function() tw(b, {BackgroundTransparency = 1}); tw(ic, {ImageColor3 = Lib.Theme.Sub}) end)
	end
end

local function brand(p, name, ver, props)
	local f = new("Frame", mix({Parent = p, Size = Sc(1, 1), L = {10, "H"}}, props))
	local lg = new("Frame", {Parent = f, Size = O(20, 20), R = 6, S = "Text"})
	lg:FindFirstChildOfClass("UIStroke").Thickness = 1.5
	dot(lg, "Text", {AnchorPoint = V2(.5, .5), Position = Sc(.5, .5), Size = O(6, 6), R = 3})
	label(f, name:upper(), 13, "Text", BOLD, {AutomaticSize = AX, Size = O(0, 16), LayoutOrder = 1})
	if ver ~= "" then label(f, ver, 12, "Muted", nil, {AutomaticSize = AX, Size = O(0, 16), LayoutOrder = 2, FontFace = Lib.Mono}) end
end

local function host()
	local ok, p = pcall(function() return (gethui and gethui()) or game:GetService("CoreGui") end)
	return ok and p or PL.LocalPlayer:WaitForChild("PlayerGui")
end

local function shell(name, size, min) -- ScreenGui + rounded main frame placed on whole pixels (+ invisible resize zones when min is set)
	local gui = new("ScreenGui", {Name = name, ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = host()})
	table.insert(Lib.Guis, gui)
	local vp = viewport()
	local main = new("Frame", {Parent = gui, Position = O(px((vp.X - size.X) / 2), px((vp.Y - size.Y) / 2)), Size = O(size.X, size.Y), BackgroundTransparency = 0, R = 12, S = "Line", T = {BackgroundColor3 = "Bg"}})
	for _, z in ipairs(min and {{U(1, -6, 0, 16), U(0, 6, 1, -32), 1, 0}, {U(0, 16, 1, -6), U(1, -32, 0, 6), 0, 1}, {U(1, -16, 1, -16), O(16, 16), 1, 1}} or {}) do
		track(new("Frame", {Parent = main, Position = z[1], Size = z[2], Active = true, ZIndex = 10}), function()
			local s = main.AbsoluteSize
			return function(d) main.Size = O(px(math.max(min.X, s.X + d.X * z[3])), px(math.max(min.Y, s.Y + d.Y * z[4]))) end
		end)
	end
	return gui, main
end

-- Notifications ------------------------------------------------------------------------------------------------------
-- Lib:Notify{Title, Text, Type = "Info"|"Success"|"Warning"|"Error", Duration = seconds (0 keeps it until clicked)} -> {Close}
local KIND, KICON, stack = {Info = "Accent", Success = "Success", Warning = "Warning", Error = "Danger"}, {Info = "info", Success = "circle-check", Warning = "triangle-alert", Error = "circle-x"}, nil
function Lib:Notify(o)
	o = mix({Title = "Notice", Text = "", Type = "Info", Duration = 4}, o)
	if not (stack and stack.Parent) then
		local gui = new("ScreenGui", {Name = "HalcyonNotify", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 100, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = host()})
		table.insert(Lib.Guis, gui)
		stack = new("Frame", {Parent = gui, AnchorPoint = V2(1, 1), Position = U(1, -24, 1, -24), Size = U(0, 320, 1, -48), L = 8})
		stack.UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	end

	local W, color = 320, KIND[o.Type] or "Accent"
	local body = o.Text ~= "" and measure(o.Text, 12, 260) or 0
	local H = body > 0 and 50 + body or 48
	local wrap = new("Frame", {Parent = stack, Size = O(W, 0), LayoutOrder = nx()})
	local card = new("Frame", {Parent = wrap, Position = O(W + 24, 0), Size = O(W, H), BackgroundTransparency = 0, R = 12, S = "Border", T = {BackgroundColor3 = "Card"}})
	icon(card, KICON[o.Type] or "info", {Position = O(16, 16), T = {ImageColor3 = color}})
	label(card, o.Title, 14, "Text", MED, {Position = O(44, 15), Size = O(260, 18), TextTruncate = Enum.TextTruncate.AtEnd})
	if body > 0 then label(card, o.Text, 12, "Sub", nil, {Position = O(44, 35), Size = O(260, body), TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top}) end
	local bar = o.Duration > 0 and new("Frame", {Parent = card, AnchorPoint = V2(0, 1), Position = Sc(0, 1), Size = U(1, 0, 0, 2), BackgroundTransparency = .55, T = {BackgroundColor3 = color}})
	fade(card, true, nil, true)

	local closed
	local function close()
		if closed then return end
		closed = true
		local i = table.find(active, close); if i then table.remove(active, i) end
		tw(card, {Position = O(W + 24, 0)}, .3, QUINT, Enum.EasingDirection.In)
		fade(card, true, .25)
		task.delay(.22, function()
			tw(wrap, {Size = O(W, 0)}, .22)
			task.wait(.24)
			wrap:Destroy(); prune()
		end)
	end
	new("TextButton", {Parent = card, Size = Sc(1, 1), ZIndex = 5}).Activated:Connect(close)

	table.insert(active, close)
	for _ = 1, #active - 5 do active[1]() end -- at most five on screen
	tw(wrap, {Size = O(W, H)}, .3, QUINT)
	tw(card, {Position = O(0, 0)}, .4, QUINT)
	fade(card, false, .3)
	if bar then
		tw(bar, {Size = U(0, 0, 0, 2)}, o.Duration, LINEAR)
		task.delay(o.Duration, close)
	end
	return {Close = close}
end

-- Loading / transition screen ----------------------------------------------------------------------------------------
-- Lib:Loading{Name, Version, Status, Steps = {{text, seconds}, ...}, Blur = true, Callback} -> {Set(alpha, text, time), Close()}
-- With Steps the screen plays itself and closes when finished; otherwise drive it with :Set() and :Close().
function Lib:Loading(o)
	o = mix({Name = "Halcyon", Version = "", Status = "Initializing", Blur = true, Callback = function() end}, o)
	local gui = new("ScreenGui", {Name = o.Name .. "Loader", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 90, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = host()})
	table.insert(Lib.Guis, gui)
	local root = new("Frame", {Parent = gui, Size = Sc(1, 1)})
	new("Frame", {Parent = root, Size = Sc(1, 1), Active = true, BackgroundTransparency = .1, T = {BackgroundColor3 = "Bg"}})
	local vp = viewport()
	local mx, my = px((vp.X - 240) / 2), px((vp.Y - 150) / 2)
	local mid = new("Frame", {Parent = root, Position = O(mx, my + 14), Size = O(240, 150)})
	local logo = new("Frame", {Parent = mid, Position = O(98, 0), Size = O(44, 44), R = 12, S = "Text"})
	logo:FindFirstChildOfClass("UIStroke").Thickness = 2
	dot(logo, "Text", {AnchorPoint = V2(.5, .5), Position = Sc(.5, .5), Size = O(8, 8), R = 4})
	label(mid, o.Name:upper(), 15, "Text", BOLD, {Position = O(0, 62), Size = U(1, 0, 0, 20), TextXAlignment = CEN})
	label(mid, o.Version, 12, "Muted", nil, {Position = O(0, 84), Size = U(1, 0, 0, 16), TextXAlignment = CEN, FontFace = Lib.Mono})
	local bar = new("Frame", {Parent = mid, Position = O(0, 118), Size = U(1, 0, 0, 4), BackgroundTransparency = 0, R = 2, T = {BackgroundColor3 = "Track"}})
	local fill = new("Frame", {Parent = bar, Size = Sc(0, 1), BackgroundTransparency = 0, R = 2, T = {BackgroundColor3 = "Accent"}})
	local status = label(mid, o.Status, 12, "Sub", nil, {Position = O(0, 130), Size = U(.75, 0, 0, 16), TextTruncate = Enum.TextTruncate.AtEnd})
	local pct = label(mid, "0%", 12, "Muted", nil, {Position = O(180, 130), Size = O(60, 16), TextXAlignment = RIGHT, FontFace = Lib.Mono})
	fade(root, true, nil, true)

	local blur
	if o.Blur then
		blur = Instance.new("BlurEffect")
		blur.Size, blur.Parent = 0, game:GetService("Lighting")
		table.insert(Lib.Guis, blur)
		tw(blur, {Size = 16}, .5)
	end
	fade(root, false, .4)
	tw(mid, {Position = O(mx, my)}, .6, QUINT)

	local prog, closed = Instance.new("NumberValue"), false
	prog.Changed:Connect(function(x) fill.Size, pct.Text = Sc(x, 1), string.format("%d%%", math.floor(x * 100 + .5)) end)
	local spin = TS:Create(logo, TweenInfo.new(1.1, QUINT, Enum.EasingDirection.InOut, -1, false, .1), {Rotation = 90}) -- 90 degrees is a square's symmetry, so the loop is seamless
	spin:Play()

	local ld = {}
	function ld:Set(a, text, t)
		if text then status.Text = text end
		tw(prog, {Value = math.clamp(a, 0, 1)}, t or .35)
	end
	function ld:Close()
		if closed then return end
		closed = true
		ld:Set(1, "Ready")
		task.delay(.5, function()
			spin:Cancel()
			fade(root, true, .4)
			if blur then tw(blur, {Size = 0}, .4) end
			task.wait(.4)
			if blur then blur:Destroy() end
			prog:Destroy(); gui:Destroy()
			task.spawn(o.Callback)
		end)
	end

	if o.Steps then
		task.spawn(function()
			local total, done = 0, 0
			for _, st in ipairs(o.Steps) do total += st[2] end
			total = math.max(total, .01)
			for _, st in ipairs(o.Steps) do
				done += st[2]
				ld:Set(done / total, st[1], st[2])
				task.wait(st[2])
			end
			ld:Close()
		end)
	end
	return ld
end

-- Elements -----------------------------------------------------------------------------------------------------------
local TabM = {}

-- A group is a labelled card holding rows; rows are separated by inset hairlines (the first visible row hides its own).
local function newGroup(tab, title)
	local g = {rows = {}}
	if title then
		g.Head = label(tab.Page, title:upper(), 12, "Sub", MED, {Size = U(1, 0, 0, 44), TextYAlignment = Enum.TextYAlignment.Bottom, P = {0, 0, 10, 4}, LayoutOrder = nx()})
	else
		g.Head = new("Frame", {Parent = tab.Page, Size = U(1, 0, 0, 20), LayoutOrder = nx()})
	end
	g.Card = new("Frame", {Parent = tab.Page, Size = U(1, 0, 0, 0), AutomaticSize = AY, BackgroundTransparency = 0, R = 12, S = "Line", L = 0, LayoutOrder = nx(), T = {BackgroundColor3 = "Card"}})
	table.insert(tab.Groups, g)
	tab.Group = g
	return g
end

local function row(tab, o) -- optional icon tile + label/description on the left; returns r and a right-aligned container for the control
	local g = tab.Group or newGroup(tab)
	local r = new("Frame", {Parent = g.Card, Size = U(1, 0, 0, 56), LayoutOrder = nx()})
	local div = line(r, {Position = O(16, 0), Size = U(1, -32, 0, 1), Visible = #g.rows > 0})
	local x = 16
	if o.Icon then
		local tile = new("Frame", {Parent = r, AnchorPoint = V2(0, .5), Position = U(0, 16, .5, 0), Size = O(32, 32), BackgroundTransparency = 0, R = 8, S = "Line", T = {BackgroundColor3 = "Raised"}})
		icon(tile, o.Icon, {AnchorPoint = V2(.5, .5), Position = Sc(.5, .5), T = {ImageColor3 = "Sub"}})
		x = 60
	end
	local t = new("Frame", {Parent = r, AnchorPoint = V2(0, .5), Position = U(0, x, .5, 0), Size = U(.5, -x, 0, 0), AutomaticSize = AY, L = 2})
	label(t, o.Name, 14, "Text", MED, {Size = U(1, 0, 0, 18), LayoutOrder = 1, TextTruncate = Enum.TextTruncate.AtEnd})
	if o.Desc then label(t, o.Desc, 12, "Sub", nil, {Size = U(1, 0, 0, 16), LayoutOrder = 2, TextTruncate = Enum.TextTruncate.AtEnd}) end
	local right = new("Frame", {Parent = r, AnchorPoint = V2(1, .5), Position = U(1, -16, .5, 0), Size = O(0, 0), AutomaticSize = AXY, L = {10, "H"}})
	g.rows[#g.rows + 1] = {Frame = r, Div = div, Text = string.lower(o.Name .. " " .. (o.Desc or ""))} -- searchable
	return r, right
end
local function fl(o) if o.Flag == nil then return o.Name end return o.Flag end
local function fire(o) return function() if o.Callback then task.spawn(o.Callback) end end end

function TabM:Section(s) newGroup(self, s) end

function TabM:Toggle(o) -- {Name, Desc, Icon, Flag, Default, Keybind = Enum.KeyCode|true, Callback(bool)}
	local _, right = row(self, o)
	local state
	local tr, upT = new("TextButton", {Parent = right, LayoutOrder = 2, Size = O(40, 22), BackgroundTransparency = 0, R = 11, T = {BackgroundColor3 = function(t) return state and t.Accent or t.Track end}})
	local knobF, upK = new("Frame", {Parent = tr, AnchorPoint = V2(0, .5), Position = U(0, 3, .5, 0), Size = O(16, 16), BackgroundTransparency = 0, R = 8,
		T = {BackgroundColor3 = function(t) return state and t.OnAccent or t.Sub end}})
	local set = bind(o, o.Default or false, function(v) state = v; upT(); upK(); tw(knobF, {Position = U(0, v and 21 or 3, .5, 0)}) end)
	tr.Activated:Connect(function() set(not state) end)
	if o.Keybind then chip(right, fl(o), o.Keybind, function() set(not state) end) end
	return {Set = set}
end

function TabM:Slider(o) -- {Name, Desc, Icon, Flag, Min, Max, Step, Default, Suffix, Callback(number)}
	local _, right = row(self, o)
	local min, max, step = o.Min or 0, o.Max or 100, o.Step or 1
	local val = label(right, "", 12, "Sub", nil, {LayoutOrder = 2, Size = O(52, 20), TextXAlignment = RIGHT, FontFace = Lib.Mono})
	local hit = new("TextButton", {Parent = right, LayoutOrder = 1, Size = O(150, 20)})
	local bar = new("Frame", {Parent = hit, AnchorPoint = V2(0, .5), Position = Sc(0, .5), Size = U(1, 0, 0, 4), BackgroundTransparency = 0, R = 2, T = {BackgroundColor3 = "Track"}})
	local fill = new("Frame", {Parent = bar, Size = Sc(0, 1), BackgroundTransparency = 0, R = 2, T = {BackgroundColor3 = "Accent"}})
	local thumb = new("Frame", {Parent = bar, AnchorPoint = V2(.5, .5), Size = O(14, 14), BackgroundTransparency = 0, R = 7, S = "Card", T = {BackgroundColor3 = "Accent"}})
	thumb:FindFirstChildOfClass("UIStroke").Thickness = 3
	local function snap(v) return math.clamp(math.floor((v - min) / step + .5) * step + min, min, max) end
	local set = bind(o, snap(o.Default or min), function(v)
		local a = (v - min) / (max - min)
		fill.Size, thumb.Position, val.Text = Sc(a, 1), Sc(a, .5), string.format("%g", v) .. (o.Suffix or "")
	end)
	track(hit, function() return function(_, pos) set(snap(min + (max - min) * math.clamp((pos.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1))) end end)
	return {Set = set}
end

local function options(o) return type(o.Options) == "function" and o.Options() or o.Options end

function TabM:Dropdown(o) -- {Name, Desc, Icon, Flag, Options = {...}|function, Default, Callback(option)}
	local _, right = row(self, o)
	local b, t = field(right)
	local d = o.Default; if d == nil and type(o.Options) == "table" then d = o.Options[1] end
	local cur
	local set = bind(o, d, function(v) cur = v; t.Text = tostring(v or "") end)
	b.Activated:Connect(function() self.Win.Menu(b, options(o), function(x) return x == cur end, set) end)
	return {Set = set}
end

function TabM:MultiDropdown(o) -- {Name, Desc, Icon, Flag, Options = {...}|function, Default = {...}, Max, Callback({...})}; the value is an array
	local _, right = row(self, o)
	local b, t = field(right)
	local sel, count = {}, 0
	local set = bind(o, o.Default or {}, function(v)
		v = type(v) == "table" and v or {}
		sel, count = {}, #v
		for _, x in ipairs(v) do sel[x] = true end
		t.Text = count == 0 and "None" or count == 1 and tostring(v[1]) or count .. " selected"
	end)
	local function toggle(x)
		if not sel[x] and o.Max and count >= o.Max then
			Lib:Notify{Title = "Limit reached", Text = "Choose up to " .. o.Max .. ".", Type = "Warning", Duration = 2}
			return
		end
		local nv = {}
		for _, y in ipairs(options(o)) do
			if (y == x) ~= (sel[y] == true) then nv[#nv + 1] = y end -- flip x, keep everything else (and keep option order)
		end
		set(nv)
	end
	b.Activated:Connect(function() self.Win.Menu(b, options(o), function(x) return sel[x] == true end, toggle, true) end)
	return {Set = set}
end

function TabM:ColorPicker(o) -- {Name, Desc, Icon, Flag, Default = Color3|hex, Alpha = bool, Callback(Color3, alpha)}
	local _, right = row(self, o)
	local alpha, cb = o.Alpha, o.Callback
	local code = label(right, "", 12, "Sub", nil, {LayoutOrder = 1, AutomaticSize = AX, Size = O(0, 22), FontFace = Lib.Mono})
	local swatch = new("TextButton", {Parent = right, LayoutOrder = 2, Size = O(32, 22), BackgroundTransparency = 0, R = 6, S = "Border"})
	local h, s, v, a, ui, own, set = 0, 0, 1, 1

	local function refresh()
		local c, hue = Color3.fromHSV(h, s, v), Color3.fromHSV(h, 1, 1)
		local text = "#" .. string.upper(toHex(c, alpha and a))
		swatch.BackgroundColor3, code.Text = c, text
		if not ui then return end
		ui.pane.BackgroundColor3 = hue
		ui.cursor.Position, ui.cursor.BackgroundColor3 = Sc(s, 1 - v), c
		ui.hue.Position, ui.hue.BackgroundColor3 = Sc(h, .5), hue
		ui.box.Text = text
		if ui.alpha then ui.alpha.Position, ui.alpha.BackgroundColor3, ui.tint.BackgroundColor3 = Sc(a, .5), c, c end
	end
	local function commit() -- user edits: keep hue/saturation exact instead of round-tripping through hex
		own = true
		set(toHex(Color3.fromHSV(h, s, v), alpha and a))
		own = false
	end

	local d = o.Default or "ffffff"
	if typeof(d) == "Color3" then d = toHex(d, alpha and 1) end
	set = bind(mix(table.clone(o), {Callback = function(x) if cb then cb(fromHex(x)) end end}), d, function(x)
		if not own then
			local c, al = fromHex(x)
			h, s, v = c:ToHSV()
			if alpha then a = al end
		end
		refresh()
	end)

	swatch.Activated:Connect(function()
		local hy = alpha and 182 or 160
		self.Win.Popup(swatch, 220, hy + 48, function(g)
			local inner = new("Frame", {Parent = g, Position = O(10, 10), Size = O(200, hy + 28)})
			local sv = new("Frame", {Parent = inner, Size = O(200, 124)})
			local pane = new("Frame", {Parent = sv, Size = Sc(1, 1), BackgroundTransparency = 0, R = 6})
			for _, l in ipairs{{Color3.new(1, 1, 1), NumberSequence.new(0, 1), 0}, {Color3.new(0, 0, 0), NumberSequence.new(1, 0), 90}} do
				local f = new("Frame", {Parent = sv, Size = Sc(1, 1), BackgroundTransparency = 0, BackgroundColor3 = l[1], R = 6})
				new("UIGradient", {Parent = f, Transparency = l[2], Rotation = l[3]})
			end
			local cursor = knob(sv)
			area(sv, function(x, y) s, v = x, 1 - y; commit() end)

			local hue = new("Frame", {Parent = inner, Position = O(0, 136), Size = O(200, 12), BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), R = 6})
			local keys = {}
			for i = 0, 6 do keys[#keys + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6 % 1, 1, 1)) end
			new("UIGradient", {Parent = hue, Color = ColorSequence.new(keys)})
			local hueKnob = knob(hue)
			area(hue, function(x) h = x; commit() end, 12)

			local alphaKnob, tint
			if alpha then
				local at = new("Frame", {Parent = inner, Position = O(0, 158), Size = O(200, 12), BackgroundTransparency = 0, R = 6, T = {BackgroundColor3 = "Track"}})
				tint = new("Frame", {Parent = at, Size = Sc(1, 1), BackgroundTransparency = 0, R = 6})
				new("UIGradient", {Parent = tint, Transparency = NumberSequence.new(1, 0)})
				alphaKnob = knob(at)
				area(at, function(x) a = x; commit() end, 12)
			end

			local box = new("TextBox", {Parent = inner, Position = O(0, hy), Size = O(200, 28), BackgroundTransparency = 0, R = 8, S = "Border", ClearTextOnFocus = false,
				FontFace = Lib.Mono, TextSize = 12, TextXAlignment = CEN, T = {BackgroundColor3 = "Field", TextColor3 = "Text"}})
			box.FocusLost:Connect(function()
				local x = box.Text:gsub("[#%s]", "")
				if (#x == 6 or alpha and #x == 8) and x:match("^%x+$") then
					local c, al = fromHex(x)
					h, s, v = c:ToHSV()
					if alpha then a = al end
					commit()
				else refresh() end
			end)

			ui = {pane = pane, cursor = cursor, hue = hueKnob, alpha = alphaKnob, tint = tint, box = box}
			g.Destroying:Connect(function() ui = nil end)
			refresh()
		end, true)
	end)
	return {
		Set = function(c, al) set(typeof(c) == "Color3" and toHex(c, alpha and (al or a)) or c) end,
		Get = function() return Color3.fromHSV(h, s, v), a end,
	}
end

function TabM:Input(o) -- {Name, Desc, Icon, Flag, Default, Placeholder, InputIcon = "pencil-line"|false, Callback(text)}
	local _, right = row(self, o)
	local f = new("Frame", {Parent = right, Size = O(170, 32), BackgroundTransparency = 0, R = 8, S = "Border", T = {BackgroundColor3 = "Raised"}})
	local stroke = f:FindFirstChildOfClass("UIStroke")
	local ic, x = o.InputIcon, 12
	if ic == nil then ic = "pencil-line" end
	if ic then icon(f, ic, {AnchorPoint = V2(0, .5), Position = U(0, 10, .5, 0), T = {ImageColor3 = "Muted"}}); x = 34 end
	local box = new("TextBox", {Parent = f, Position = O(x, 0), Size = U(1, -x - 10, 1, 0), ClearTextOnFocus = false, ClipsDescendants = true, TextSize = 13,
		PlaceholderText = o.Placeholder or "", T = {TextColor3 = "Text", PlaceholderColor3 = "Muted"}})
	box.Focused:Connect(function() tw(stroke, {Color = Lib.Theme.Sub}) end)
	local set = bind(o, o.Default or "", function(v) box.Text = v end)
	box.FocusLost:Connect(function() tw(stroke, {Color = Lib.Theme.Border}); set(box.Text) end)
	return {Set = set, Get = function() return box.Text end}
end

function TabM:Button(o) -- {Name, Desc, Icon, Text, Primary, Callback()}
	local _, right = row(self, o)
	local b = new("TextButton", {Parent = right, Size = O(112, 32), BackgroundTransparency = 0, R = 8, S = not o.Primary and "Border" or nil, T = {BackgroundColor3 = o.Primary and "Accent" or "Raised"}})
	label(b, o.Text or o.Name, 13, o.Primary and "OnAccent" or "Text", MED, {Size = Sc(1, 1), TextXAlignment = CEN})
	local s = b:FindFirstChildOfClass("UIStroke")
	b.MouseEnter:Connect(function() if s then tw(s, {Color = Lib.Theme.Sub}) else tw(b, {BackgroundTransparency = .15}) end end)
	b.MouseLeave:Connect(function() if s then tw(s, {Color = Lib.Theme.Border}) else tw(b, {BackgroundTransparency = 0}) end end)
	b.Activated:Connect(fire(o))
end

function TabM:Keybind(o) -- {Name, Desc, Icon, Flag, Default = Enum.KeyCode, Callback()} fires when the key is pressed
	local _, right = row(self, o)
	chip(right, fl(o), o.Default, fire(o))
end

-- Window -------------------------------------------------------------------------------------------------------------
-- Lib:Window{Name, Version, Crumb, Game, Size, Min, ToggleKey, Config, Folder}
function Lib:Window(o)
	o = mix({Name = "Halcyon", Version = "", Crumb = "Game", Game = "", Size = V2(820, 560), Min = V2(720, 440), ToggleKey = Enum.KeyCode.RightShift, Config = Lib.Config, Folder = Lib.Folder}, o)
	o.Size = V2(px(o.Size.X / 2) * 2, px(o.Size.Y / 2) * 2) -- even dimensions keep centered children on whole pixels
	Lib.Folder, Lib.Config = o.Folder, o.Config
	Lib.Saved = decode(o.Config) or {}
	if Lib.Saved.__theme then Lib:SetTheme(Lib.Saved.__theme) end
	local tk = Lib.Saved.__toggle_key; if tk == nil then tk = o.ToggleKey.Name end
	Lib.Flags.__toggle_key = tk

	local gui, main = shell(o.Name, o.Size, o.Min)
	local Win, tabs, lastSection, rest = {Gui = gui}, {}, nil, nil

	-- sidebar: brand, scrolling tab list, signed-in user
	local side = new("Frame", {Parent = main, Size = U(0, 208, 1, 0)})
	line(main, {Position = O(208, 0), Size = U(0, 1, 1, 0)})
	local head = new("Frame", {Parent = side, Size = U(1, 0, 0, 64), P = {0, 0, 0, 20}})
	brand(head, o.Name, o.Version)
	line(side, {Position = O(16, 64), Size = U(1, -32, 0, 1)})
	local nav = new("ScrollingFrame", {Parent = side, Position = O(0, 65), Size = U(1, 0, 1, -129), CanvasSize = U(), AutomaticCanvasSize = AY, ScrollBarThickness = 0, P = {8, 12, 8, 12}, L = 2})
	local foot = new("Frame", {Parent = side, AnchorPoint = V2(0, 1), Position = Sc(0, 1), Size = U(1, 0, 0, 64)})
	line(foot, {Position = O(16, 0), Size = U(1, -32, 0, 1)})
	local lp = PL.LocalPlayer
	local av = new("ImageLabel", {Parent = foot, Position = O(16, 16), Size = O(32, 32), BackgroundTransparency = 0, R = 16, S = "Line", T = {BackgroundColor3 = "Raised"}})
	task.spawn(function()
		local ok, img = pcall(PL.GetUserThumbnailAsync, PL, lp.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
		if ok then av.Image = img end
	end)
	label(foot, lp.DisplayName, 13, "Text", MED, {Position = O(58, 16), Size = U(1, -74, 0, 16), TextTruncate = Enum.TextTruncate.AtEnd})
	label(foot, "@" .. lp.Name, 12, "Muted", nil, {Position = O(58, 32), Size = U(1, -74, 0, 16), TextTruncate = Enum.TextTruncate.AtEnd})

	-- content: top bar (breadcrumb, search, window controls) + page area
	local content = new("Frame", {Parent = main, Position = O(209, 0), Size = U(1, -209, 1, 0), ClipsDescendants = true})
	local top = new("Frame", {Parent = content, Size = U(1, 0, 0, 64)})
	line(top, {AnchorPoint = V2(0, 1), Position = Sc(0, 1)})
	local crumb = new("Frame", {Parent = top, Size = U(1, -300, 1, 0), P = {0, 0, 0, 28}, L = {6, "H"}, ClipsDescendants = true})
	label(crumb, o.Crumb, 13, "Sub", nil, {AutomaticSize = AX, Size = O(0, 18), LayoutOrder = 1})
	icon(crumb, "chevron-right", {LayoutOrder = 2, T = {ImageColor3 = "Muted"}})
	label(crumb, o.Game, 13, "Text", MED, {AutomaticSize = AX, Size = O(0, 18), LayoutOrder = 3})
	controls(top, function()
		Win:Show(false)
		Lib:Notify{Title = "Interface hidden", Text = "Press " .. tostring(Lib.Flags.__toggle_key) .. " to show it again.", Duration = 3}
	end, function() Lib:Destroy() end)
	drag(top, main); drag(head, main)

	-- search: filters the elements of every tab (and hides cards left empty)
	local function filter(q)
		q = q:lower():match("^%s*(.-)%s*$")
		for _, e in ipairs(tabs) do
			local total = 0
			for _, g in ipairs(e.groups) do
				local hits = 0
				for _, r in ipairs(g.rows) do
					local ok = q == "" or r.Text:find(q, 1, true) ~= nil
					r.Frame.Visible, r.Div.Visible = ok, ok and hits > 0
					if ok then hits += 1 end
				end
				g.Card.Visible, g.Head.Visible = q == "" or hits > 0, q == "" or hits > 0
				total += hits
			end
			e.empty.Visible = q ~= "" and total == 0
		end
	end
	local _, query = search(top, "Search", "Field", {AnchorPoint = V2(1, .5), Position = U(1, -88, .5, 0), Size = O(184, 32), Active = true})
	query:GetPropertyChangedSignal("Text"):Connect(function() filter(query.Text) end)

	function Win:Show(v)
		if v == nil then v = not main.Visible end
		main.Visible = v
		if v then
			local p = rest or main.Position
			rest = p
			main.Position = U(p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset + 12)
			tw(main, {Position = p}, .3, QUINT).Completed:Connect(function() rest = nil end)
		end
	end
	on(UIS.InputBegan, function(i, gp) if not gp and not Lib.Listening and i.KeyCode.Name == Lib.Flags.__toggle_key then Win:Show() end end)

	-- Popup: fades/slides in under anchor a; clicking outside closes it. build(group, close) fills the popup.
	function Win.Popup(a, w, h, build, right)
		local gate = new("TextButton", {Parent = main, Size = Sc(1, 1), ZIndex = 50})
		local ap, as, mp, ms = a.AbsolutePosition, a.AbsoluteSize, main.AbsolutePosition, main.AbsoluteSize
		local x = px(math.clamp(ap.X - mp.X + (right and as.X - w or 0), 8, math.max(8, ms.X - w - 8)))
		local y = px(ap.Y - mp.Y + as.Y + 6)
		if y + h > ms.Y - 8 then y = px(math.max(8, ap.Y - mp.Y - h - 6)) end -- flip above when there is no room below
		local group = new("Frame", {Parent = gate, Position = O(x, y + 6), Size = O(w, h), Active = true, BackgroundTransparency = 0, R = 10, S = "Border", T = {BackgroundColor3 = "Raised"}})
		local closed
		local function close()
			if closed then return end
			closed = true
			tw(group, {Position = O(x, y + 6)}, .12)
			fade(group, true, .12)
			task.delay(.12, function() gate:Destroy(); prune() end)
		end
		gate.Activated:Connect(close)
		build(group, close)
		fade(group, true, nil, true)
		tw(group, {Position = O(x, y)}, .2, QUINT)
		fade(group, false, .16)
		return close
	end

	-- Menu: option list popup under a; multi keeps it open. isSel(v) -> bool, pick(v). Long lists get a search field.
	function Win.Menu(a, opts, isSel, pick, multi)
		if #opts == 0 then return end
		local find = #opts > 6
		local top = find and 48 or 0
		Win.Popup(a, a.AbsoluteSize.X, math.min(#opts * 32 + 6, 198) + top, function(g, close)
			local box
			if find then _, box = search(g, "Search", "Field", {Position = O(8, 8), Size = U(1, -16, 0, 32)}) end
			local m = new("ScrollingFrame", {Parent = g, Position = O(0, top), Size = U(1, 0, 1, -top), CanvasSize = U(), AutomaticCanvasSize = AY, ScrollBarThickness = 2, P = 4, L = 2,
				T = {ScrollBarImageColor3 = "Border"}})
			local rows = {}
			for i, v in ipairs(opts) do
				local b = new("TextButton", {Parent = m, Size = U(1, 0, 0, 30), LayoutOrder = i, R = 6, T = {BackgroundColor3 = "Track"}})
				local t = label(b, tostring(v), 13, "Sub", nil, {Position = O(10, 0), Size = U(1, -42, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd})
				local mark = tick(b, multi)
				local function paint(now)
					local state = isSel(v)
					mark(state, now)
					apply(t, {TextColor3 = state and Lib.Theme.Text or Lib.Theme.Sub}, now)
				end
				paint(true)
				b.MouseEnter:Connect(function() tw(b, {BackgroundTransparency = 0}) end)
				b.MouseLeave:Connect(function() tw(b, {BackgroundTransparency = 1}) end)
				b.Activated:Connect(function()
					pick(v)
					if multi then paint() else close() end
				end)
				rows[i] = {Frame = b, Text = tostring(v):lower()}
			end
			local none = label(m, "No matches", 13, "Muted", nil, {Size = U(1, 0, 0, 30), LayoutOrder = #opts + 1, Visible = false, TextXAlignment = CEN})
			if box then
				box:GetPropertyChangedSignal("Text"):Connect(function()
					local q, hits = box.Text:lower(), 0
					for _, r in ipairs(rows) do
						local ok = q == "" or r.Text:find(q, 1, true) ~= nil
						r.Frame.Visible = ok
						if ok then hits += 1 end
					end
					none.Visible = hits == 0
				end)
				if not UIS.TouchEnabled then task.defer(box.CaptureFocus, box) end
			end
		end)
	end

	local function choose(e)
		for _, x in ipairs(tabs) do x.set(x == e) end
		e.page.Position = O(0, 72); tw(e.page, {Position = O(0, 65)}, .25, QUINT)
	end

	function Win:Tab(t) -- {Name, Icon = lucide name, Section, Title, Desc}
		t = mix({Icon = "folder", Section = "GAME", Title = t.Name}, t)
		if t.Section ~= lastSection then
			lastSection = t.Section
			label(nav, t.Section:upper(), 11, "Muted", MED, {Size = U(1, 0, 0, 30), TextYAlignment = Enum.TextYAlignment.Bottom, P = {0, 0, 6, 10}, LayoutOrder = nx()})
		end
		local act = false
		local c = function(th) return act and th.Text or th.Sub end
		local item = new("TextButton", {Parent = nav, Size = U(1, 0, 0, 36), LayoutOrder = nx(), R = 8, T = {BackgroundColor3 = "Raised"}})
		local pill = new("Frame", {Parent = item, Position = O(0, 10), Size = O(3, 16), R = 2, T = {BackgroundColor3 = "Accent"}})
		local _, u1 = icon(item, t.Icon, {Position = O(14, 10), T = {ImageColor3 = c}})
		local _, u2 = label(item, t.Name, 14, c, MED, {Position = O(40, 0), Size = U(1, -48, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd})
		local page = new("ScrollingFrame", {Parent = content, Position = O(0, 65), Size = U(1, 0, 1, -65), Visible = false, CanvasSize = U(), AutomaticCanvasSize = AY,
			ScrollBarThickness = 3, ElasticBehavior = Enum.ElasticBehavior.Never, P = {24, 28, 28, 28}, L = 0, T = {ScrollBarImageColor3 = "Border"}})
		label(page, t.Title, 26, "Text", BOLD, {Size = U(1, 0, 0, 34), LayoutOrder = nx()})
		label(page, t.Desc or "", 13, "Sub", nil, {Size = U(1, 0, 0, 20), LayoutOrder = nx(), TextTruncate = Enum.TextTruncate.AtEnd})

		local e = {page = page, groups = {}}
		e.empty = label(page, "No results", 13, "Muted", nil, {Size = U(1, 0, 0, 64), TextXAlignment = CEN, LayoutOrder = 1000000, Visible = false})
		function e.set(v) act, page.Visible = v, v; u1(); u2(); tw(item, {BackgroundTransparency = v and 0 or 1}); tw(pill, {BackgroundTransparency = v and 0 or 1}) end
		tabs[#tabs + 1] = e
		item.Activated:Connect(function() choose(e) end)
		item.MouseEnter:Connect(function() if not act then tw(item, {BackgroundTransparency = .6}) end end)
		item.MouseLeave:Connect(function() if not act then tw(item, {BackgroundTransparency = 1}) end end)
		if #tabs == 1 then choose(e) end
		return setmetatable({Win = Win, Page = page, Groups = e.groups}, {__index = TabM})
	end

	function Win:Settings() -- built-in tab: theme, UI toggle key, config management
		local t = Win:Tab({Name = "Settings", Icon = "settings", Section = "SYSTEM", Desc = "Appearance and configuration."})
		t:Section("Appearance")
		t:Dropdown({Name = "Theme", Desc = "Color scheme for the interface.", Icon = "palette", Flag = "__theme", Default = Lib.ThemeName, Callback = function(v) Lib:SetTheme(v) end,
			Options = function() local r = {} for k in pairs(Lib.Themes) do r[#r + 1] = k end table.sort(r) return r end})
		t:Keybind({Name = "Toggle UI", Desc = "Show or hide the window.", Icon = "keyboard", Flag = "__toggle", Default = o.ToggleKey})
		t:Section("Configuration")
		local name = t:Input({Name = "Config name", Desc = "Used when saving, loading or deleting.", Icon = "file-text", Flag = false, Default = Lib.Config, Placeholder = "default"})
		t:Dropdown({Name = "Saved configs", Desc = "Pick an existing config.", Icon = "folder-open", Flag = false, Options = function() return Lib:List() end, Callback = name.Set})
		for _, b in ipairs{{"Save", "Write current values to this config.", "save"}, {"Load", "Apply values from this config.", "download"}, {"Delete", "Remove this config file.", "trash-2"}} do
			t:Button({Name = b[1], Desc = b[2], Icon = b[3], Callback = function()
				local c = name.Get(); if c == "" then c = Lib.Config end
				local ok = Lib[b[1]](Lib, c) ~= false
				Lib:Notify{Title = ok and ("Config " .. b[1]:lower() .. "d") or "Config not found", Text = c, Type = ok and "Success" or "Error", Duration = 2.5}
			end})
		end
		return t
	end

	return Win
end

return Lib
