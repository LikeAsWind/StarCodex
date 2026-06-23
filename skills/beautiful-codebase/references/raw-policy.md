# Raw Policy 路 Raw 鑷敱灞傝鍒欙紙浠ｇ爜鍒嗘瀽鐗瑰寲锛?

> **浣曟椂璇?*锛歅hase 4 鍐欐瘡鑺傛椂锛屽綋浣犳兂鑴辩 reacticle 缁勪欢鍗忚銆佺敤瑁?HTML / SVG /
> 鑷畾涔?React 瀹炵幇鏌愭瑙嗚鏃讹紱Section 07 SVG 澶嶆潅搴︾儹鍥?/ 灏侀潰 / 鏋佸皯鏁?Mermaid
> 琛ㄨ揪涓嶄簡鐨勫浘銆?
>
> **閰嶅鏂囦欢**锛歚references/component-policy.md`锛堝厛纭鎯冲仛鐨勪簨涓嶈兘鐢ㄧ粍浠跺仛锛?路
> `theme-profiles/<id>.md`锛堟嬁 `--ra-*` token锛?路 `references/section-build.md` 搂1.1
> 锛坄raw-blocks/` 鏂囦欢浣嶇疆锛夈€?

Reacticle 鐨?`<Raw>` 鑷敱灞傚湪 `beautiful-article` 閲岃骞挎硾浣跨敤鈥斺€旀枃绔犳槸鍒涗綔濯掍粙锛岃嚜鐢?
灞傛槸琛ㄧ幇鍔涚殑鏍稿績銆?*`beautiful-codebase` 鎶婂畠鏀剁揣**锛氭姤鍛婃槸鍏充簬鐪熷疄浠ｇ爜鐨勪簨瀹為檲杩帮紝
鑷敱灞傛槸**淇濈暀閫冪敓鍙?*锛屼笉鏄父瑙勭粍浠躲€傛墍浠ユ湰鏂囦欢鏈川涓婃槸"浠€涔堟椂鍊?*涓嶅厑璁?*鐢?Raw"
鐨勬竻鍗曘€?

## 1 路 Raw 浣曟椂鍏佽
- `viewBox` 鎸夊疄闄呭唴瀹硅绠楋細鍐欏畬鎵€鏈夎妭鐐瑰拰杩炵嚎鍚庯紝鍙栨墍鏈?rect 鐨勬渶澶?(y + height) 鍜屾墍鏈?line 鐨勬渶澶?y2锛屽姞搴曢儴鐣欑櫧 40px 浣滀负 viewBox 楂樺害锛涜嚦灏?280px
鍙湪浠ヤ笅鍦烘櫙鍏佽锛?

1. **Section 07 Code Health Heatmap 路 SVG 澶嶆潅搴︾儹鍥?* 鈥斺€?Mermaid 琛ㄨ揪涓嶄簡锛涢鑹叉槧灏?
   鍒?`--ra-status-*` token锛岀煩褰㈡牸瀛愬ぇ灏忔槧灏勫埌 LOC / 澶嶆潅搴︺€?
2. **Cover 路 灏侀潰棰樺浘** 鈥斺€?SVG 棰樺浘鎴?SVG + HTML 鎺掔増鐨勪功灏佸紡灏侀潰锛堣瑙?
   `references/cover.md` 宸茶鏄庣殑纭害鏉燂級銆?
3. **鏋佸皯鏁?Mermaid 琛ㄨ揪涓嶄簡鐨勫彲瑙嗗寲** 鈥斺€?渚嬪鐪熷疄鏁版嵁鎶樼嚎瀵规瘮銆侀渶瑕佺簿纭儚绱犲竷灞€鐨?
   鏃跺簭瀵规瘮鍥俱€?*涓捐瘉璐ｄ换鍦ㄤ綔鑰?*锛氫綘瑕佽娓?涓轰粈涔?Mermaid 涓嶈"銆?
4. **寰皬鎺掔増澧炲己** 鈥斺€?涓€涓苟鎺掑姣斿皬妗嗐€佷竴娈甸渶瑕?hover 鎻ず鐨勭粏鑺傛姌鍙犻潰鏉匡紙濡傛灉
   `<Callout>` / `<Detail>` 宸茬粡鑳藉仛灏变笉瑕?Raw锛夈€?

## 2 路 Raw 浣曟椂绂佹

涓嬮潰杩欎簺涓€寰?fail锛孲ection Reviewer 鎶芥煡鏃朵細鐩存帴鎷掓帀锛?

| 绂佹鍋氱殑浜?| 涓轰粈涔?|
|---|---|
| 缁堢鍛戒护鎵撳瓧鏈烘晥鏋?| 鎶ュ憡涓嶆槸 demo锛涜楗?|
| 浠ｇ爜闆?/ matrix 瀛楃娴?| 鍚屼笂 |
| 绮掑瓙鑳屾櫙 / 闇撹櫣鍙戝厜 / CRT 婊ら暅 | 鍚屼笂锛涜繚鍙?terminal 涓婚"鍏嬪埗"鍘熷垯 |
| 婊氬姩鎻ず / 鑷姩鎾斁鍔ㄧ敾 | 鎶ュ憡搴斿彲闈欐€佹墦鍗帮紱鍔ㄧ敾骞叉壈闃呰 |
| 鐢?Raw 澶嶅埢 `<Mermaid>` / `<SourcePointers>` / `<CodeBlock>` | 宸茬粡鏈夌粍浠朵簡 |
| Section 05 鍏ュ彛娴佺▼鍥剧敤 Raw SVG 鐢?| **蹇呴』** Mermaid锛涚粺涓€娓叉煋绠＄嚎 + 涓婚 token |
| 澶嶆潅琛ㄥ崟 / dashboard / 瀹屾暣浜у搧鍘熷瀷 | 鎶ュ憡涓嶆槸搴旂敤 |
| 寮曞叆 React state / useEffect 鍋?瀹炴椂" / "鍙皟" 妯″瀷 | 鎶ュ憡鏄?snapshot锛涗笉瑕佸仛浜や簰 |
| 澶栭儴 `<img src="https://...">` | 鍗曟枃浠?HTML 涓嶈兘鑱旂綉锛沘sset-policy 榛樿 `none` |
| 澶栭儴 `<script src="https://cdn...">` | 鍗曟枃浠?HTML 涓嶈兘渚濊禆 CDN |
| 琛屽唴 `style={{color: "#abc"}}` / `style="background: rgb(...)"` | 杩濆弽 token 椹卞姩 |
| 鍦?Raw 閲?`<style>` 閲嶅畾涔?`--ra-*` token | 鐮村潖涓婚鍒囨崲 |

## 3 路 Raw 蹇呴』鐢ㄤ富棰?token

鏃犱緥澶栵細鎵€鏈夐鑹?/ 瀛椾綋 / 闂磋窛 / 鍦嗚蹇呴』鍙栬嚜涓婚鍙橀噺锛坄var(--ra-terminal-bg)` /
`var(--ra-status-red)` / `var(--ra-mono-text)` / `var(--ra-space-4)` ...锛夛紝浠?
`theme-profiles/<id>.md` 搂2 Token 琛ㄦ妱銆俁aw 閲屽啓棰滆壊鐨?only 鍏佽鏍煎紡锛?

```tsx
<rect fill="var(--ra-status-red)" />
<div style={{ color: "var(--ra-terminal-fg)", padding: "var(--ra-space-3)" }}>...</div>
```

**鍞竴渚嬪**锛歋VG 鐨?`viewBox` / `width` / `height` / `x` / `y` / `cx` / `cy` 绛夊嚑浣?
灞炴€у厑璁哥敤 number / px / rem 瀛楅潰閲忊€斺€斿畠浠槸鍑犱綍鍙傛暟涓嶆槸璁捐 token銆?

## 4 路 澶у潡 Raw 闅旂鍒?`raw-blocks/`

> 30 琛岀殑 Raw 蹇呴』鎶藉埌 `<project>-analysis/article/raw-blocks/NN-<slug>.tsx`锛岀敱瀵瑰簲
section 鏂囦欢 import锛?

```tsx
// article/raw-blocks/07-complexity-heatmap.tsx
export function ComplexityHeatmap({ data }: { data: HeatmapCell[] }) {
  return (
    <svg viewBox="0 0 800 400" width="100%" role="img" aria-label="澶嶆潅搴︾儹鍥?>
      {data.map((cell) => (
        <rect
          key={cell.id}
          x={cell.x} y={cell.y} width={cell.w} height={cell.h}
          fill={`var(--ra-status-${cell.severity})`}
        />
      ))}
    </svg>
  );
}

// article/sections/07-code-health.tsx
import { Section } from "reacticle";
import { ComplexityHeatmap } from "../raw-blocks/07-complexity-heatmap";

export function SectionCodeHealth() {
  const data = /* 浠?discovery/complexity.jsonl 瑙ｆ瀽 */;
  return (
    <Section index="07" title="Code Health Heatmap">
      <p>...</p>
      <ComplexityHeatmap data={data} />
      <p>...</p>
    </Section>
  );
}
```

**濂藉**锛?

- Section 鏂囦欢淇濇寔鍙锛堜笉琚?200 琛?SVG 鎾戠垎锛夈€?
- 澶?Agent 骞惰涓嬩笉浼氬洜涓哄法鍨?Raw 鍧楅樆濉為噸璇汇€?
- 鍗曠嫭淇 / 鍗曠嫭 review Raw 鍧楁洿瀹规槗銆?

## 5 路 Raw 涓?Mermaid 鐨勫叧绯?

**Mermaid 浼樺厛 路 Raw 鍏滃簳**銆?

| 鎯崇敾鐨勫浘 | 鐢ㄤ粈涔?|
|---|---|
| 涓氬姟瀹炰綋鍏崇郴 | `<Mermaid>` `graph LR` |
| 妯″潡渚濊禆 | `<Mermaid>` `graph` |
| 鍏ュ彛娴佺▼ / 璋冪敤閾?| `<Mermaid>` `flowchart TD`锛圫ection 05 蹇呴』锛?|
| 鏃跺簭鍥?| `<Mermaid>` `sequenceDiagram` |
| 绠€鍗曠姸鎬佹満 | `<Mermaid>` `stateDiagram-v2` |
| 澶嶆潅搴?/ 鐑害浜岀淮缃戞牸 | Raw SVG锛坢ermaid 涓嶆敮鎸佸瘑闆嗘牸瀛愶級 |
| 鐪熷疄鏁版嵁鎶樼嚎瀵规瘮 | Raw SVG锛坢ermaid 鏀寔鏈夐檺锛?|
| 灏侀潰棰樺浘 | Raw SVG / Raw HTML |

鍙湪鍙虫爮鐨?3 绫诲満鏅€冭檻 Raw锛涘叾瀹冮兘鍏堣瘯 Mermaid銆?

## 6 路 Raw 5 鏉¤嚜妫€锛堝啓瀹屾瘡涓?Raw 鍧楅兘璺戜竴閬嶏級

- [ ] **鍒犳帀瀹冿紝鎶ュ憡鐞嗚В浼氬彉宸悧锛?* 涓嶄細 鈫?鐮嶆帀锛堜綘鏄湪鍋氳楗帮級銆?
- [ ] **鍙敤 `--ra-*` token 浜嗗悧锛?* 缈讳竴閬嶆簮鐮佹悳 `#` 鍜?`rgb(`锛屼笉搴旀壘鍒帮紙SVG 鍑犱綍灞炴€ч櫎澶栵級銆?
- [ ] **娌℃湁瀹冿紝prose 娈佃惤鏈韩鑳戒笉鑳借锛?* 涓嶈兘 鈫?浣犲仛鐨勬槸瑁呴グ鏌憋紝鐮嶆帀銆?
- [ ] **绉诲姩绔兘璇诲悧锛?* 娴忚鍣ㄥ紑 mobile viewport 鐪嬶紝Raw 鍧椾笉搴旂牬鍧忔爮瀹姐€?
- [ ] **鎵撳嵃鑳借鍚楋紵** 榛戠櫧鎵撳嵃锛坱erminal 涓婚鏆楀簳锛侊級鐘舵€佷笅棰滆壊瀵规瘮鏄惁浠嶅彲杈紵璇﹁
  
浠讳綍涓€鏉＄瓟鍚?鈫?鏀瑰畬鎴栫爫鎺夈€?*涓嶈甯︾潃宸茬煡闂浜や粯**鈥斺€擲ection Reviewer 浼氬彂鐜般€?

## 7 路 涓€涓弽渚?

```tsx
// 鉂?杩欐槸 raw-policy 绂佹鐨?
<Raw>
  <div style={{
    background: "#0E1116",                    // 鉂?纭紪鐮侀鑹?
    color: "#00FF00",                          // 鉂?缁堢缁胯楗帮紱闈炶涔夎壊
    fontFamily: "Courier New, monospace",     // 鉂?涓嶇敤 token
    animation: "typing 2s steps(40) infinite" // 鉂?鎵撳瓧鏈哄姩鐢昏楗?
  }}>
    {`> Analyzing codebase...`}
  </div>
</Raw>
```

姝ｇ‘鍋氭硶锛氱洿鎺?`<Callout tone="info">鏈妭鐢卞垎鏋?SubAgent 鑷姩鐢熸垚</Callout>` 鈥斺€?涓€琛?
缁勪欢瑙ｅ喅锛屾棤 Raw銆?

## 8 路 涓€涓渚?

```tsx
// 鉁?鍚堢悊锛歋ection 07 澶嶆潅搴︾儹鍥惧繀椤?Raw锛孧ermaid 琛ㄨ揪涓嶄簡瀵嗛泦缃戞牸
export function ComplexityHeatmap({ cells }: { cells: Cell[] }) {
  return (
    <svg viewBox="0 0 800 400" width="100%" role="img"
         aria-label="鎸夋枃浠惰仛鍚堢殑鍦堝鏉傚害鐑浘">
      {cells.map((c) => (
        <rect key={c.path}
              x={c.x} y={c.y} width={c.w} height={c.h}
              fill={`var(--ra-status-${c.tier})`}>
          <title>{c.path} 路 CC={c.cc}</title>
        </rect>
      ))}
    </svg>
  );
}
```

棰滆壊 token銆佸嚑浣曞弬鏁?number銆乣<title>` 鍏冪礌鍋?hover tooltip + 鍙闂€с€佹棤瑁呴グ鍔ㄧ敾銆?
閫氳繃銆?

