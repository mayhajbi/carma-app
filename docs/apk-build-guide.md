# מדריך: בניית APK לאנדרואיד עם שרת Mock על Render

מדריך זה מתעד את התהליך המלא להפעלת אפליקציית Expo כ-APK עצמאי לאנדרואיד,
כאשר האפליקציה מחוברת לשרת Mock (Express) שרץ ב-Render.

---

## דרישות מקדימות

- Node.js 18+
- חשבון GitHub
- חשבון Expo (חינמי) — [expo.dev](https://expo.dev)
- חשבון Render (חינמי) — [render.com](https://render.com)

---

## שלב 1 — תיקון תלויות חסרות

לפני הכל, ודא שהחבילות הבאות מותקנות:

```bash
npx expo install babel-preset-expo
npx expo install expo@~54.0.35   # התאם לגרסת ה-SDK של הפרויקט
```

בדיקת תקינות הפרויקט:

```bash
npx expo-doctor
```

כל הבדיקות חייבות לעבור לפני שממשיכים.

---

## שלב 2 — פרסום שרת ה-Mock ב-Render

### הכנת השרת

ודא שהפורט נקרא מ-environment variable (Render מקצה פורט דינמי):

```js
// server.js
const PORT = process.env.PORT || 3000;
```

### פרסום

1. היכנס ל-[render.com](https://render.com) → **New → Web Service**
2. חבר את ה-GitHub repo
3. הגדר:

   | שדה | ערך |
   |---|---|
   | Root Directory | הנתיב לתיקיית השרת (למשל `carma-server-main/local-server`) |
   | Build Command | `npm install` |
   | Start Command | `node server.js` |
   | Instance Type | Free |

4. לחץ **Deploy**
5. לאחר הסיום — העתק את ה-URL (למשל `https://your-app.onrender.com`)

### בדיקת זמינות

```
https://your-app.onrender.com/health
```

אם מקבלים תגובת JSON עם status OK — השרת זמין.

> **שים לב:** בתוכנית החינמית של Render, השרת "נרדם" אחרי 15 דקות חוסר פעילות
> ומתעורר תוך ~30 שניות בבקשה הראשונה. מקובל לצורך Demo.

---

## שלב 3 — קונפיגורציה של האפליקציה

### 3.1 — serverConfig.ts

מצא את קובץ ה-config של השרת (בדרך כלל `src/constants/serverConfig.ts`) ועדכן:

```ts
export const USE_REAL_SERVER = true;
// ...
export const LOCAL_SERVER_URL = USE_REAL_SERVER
  ? 'https://your-app.onrender.com'   // ← URL של Render
  : getMetroOrigin();
```

### 3.2 — client.ts

חשוב: אם קיים קובץ `src/services/api/client.ts` עם URL משלו, עדכן גם אותו:

```ts
const REAL_SERVER_URL = 'https://your-app.onrender.com';
```

### 3.3 — app.json

ודא שהשם והסמל מוגדרים נכון:

```json
{
  "expo": {
    "name": "CARMA",
    "icon": "./assets/images/icon.png",
    "android": {
      "package": "com.carma.app"
    }
  }
}
```

אם אין לך קבצי Adaptive Icon — הסר את בלוק `adaptiveIcon` כדי להשתמש ב-`icon.png` בלבד.

### 3.4 — תמונות נדרשות

| קובץ | גודל | תפקיד |
|---|---|---|
| `assets/images/icon.png` | 1024×1024 | סמל האפליקציה |
| `assets/images/splash-icon.png` | כל גודל | מסך פתיחה |

---

## שלב 4 — בניית ה-APK עם EAS

### התקנת EAS CLI והתחברות

```bash
npm install -g eas-cli
eas login
```

### eas.json

ודא שקיים `eas.json` בשורש הפרויקט עם profile `preview`:

```json
{
  "build": {
    "preview": {
      "distribution": "internal"
    }
  }
}
```

### הרצת הבנייה

```bash
eas build -p android --profile preview
```

הבנייה רצה בענן (~10-15 דקות, + המתנה בתור בתוכנית חינמית).
בסיום תתקבל התראה עם קישור ישיר ל-`.apk`.

---

## שלב 5 — התקנה בטלפון

1. פתח את קישור ה-`.apk` **בדפדפן הטלפון**
2. הורד את הקובץ
3. אשר התקנה ממקור לא ידוע:
   **הגדרות → אבטחה → התקנת אפליקציות לא ידועות → אשר לדפדפן**
4. התקן

---

## שינויי קוד שבוצעו בפועל

פירוט מדויק של כל הקבצים שהיה צריך לשנות כדי שהאפליקציה תעבוד כ-APK עם שרת Render.

---

### `carma-server-main/local-server/server.js`

**בעיה:** הפורט היה hardcoded ל-3000. Render מקצה פורט דינמי ולכן השרת לא הצליח להתחיל.

```js
// לפני
const PORT = 3000;

// אחרי
const PORT = process.env.PORT || 3000;
```

---

### `src/constants/serverConfig.ts`

**בעיה:** `USE_REAL_SERVER` היה `false`, ו-URL השרת האמיתי היה placeholder.
ב-APK עצמאי אין Metro proxy, ולכן חייבים להצביע ישירות על ה-URL.

```ts
// לפני
export const USE_REAL_SERVER = false;
// ...
? 'https://carma-api.example.com'

// אחרי
export const USE_REAL_SERVER = true;
// ...
? 'https://your-app.onrender.com'
```

---

### `src/services/api/client.ts`

**בעיה:** הקובץ הגדיר `REAL_SERVER_URL` משלו (hardcoded placeholder) ולא ייבא אותו מ-`serverConfig.ts`.
גם אם מעדכנים את `serverConfig.ts` — `client.ts` עדיין שולח בקשות לכתובת הישנה.

```ts
// לפני
const REAL_SERVER_URL = 'https://carma-api.example.com';

// אחרי
const REAL_SERVER_URL = 'https://your-app.onrender.com';
```

> **חשוב:** זו הייתה הסיבה שהאפליקציה לא הצליחה להתחבר לאחר ה-deploy הראשון.
> תמיד לבדוק אם יש הגדרת URL כפולה בשני קבצים שונים.

---

### פקודות שהורצו לתיקון תלויות

```bash
# babel-preset-expo היה חסר לחלוטין מה-package.json
npx expo install babel-preset-expo

# גרסת expo הייתה מאחורי ב-patch אחד (גרם לכישלון ב-expo doctor בזמן build)
npx expo install expo@~54.0.35
```

---



| שגיאה | פתרון |
|---|---|
| `Cannot find module 'babel-preset-expo'` | `npx expo install babel-preset-expo` |
| `expo doctor` נכשל בגרסה | `npx expo install expo@~54.0.35` |
| `The system cannot find the path` עם `--tunnel` | `npx expo install @expo/ngrok@^4.0.2` |
| בקשות רשת נכשלות ב-APK | ודא ש-`REAL_SERVER_URL` עודכן גם ב-`client.ts` |

---

## הרצה מקומית במקביל (פיתוח)

להרצת השרת המקומי והאפליקציה בו-זמנית:

```bash
./dev.ps1
```

ראה [dev.ps1](../dev.ps1) בשורש הפרויקט.

---

## הערות לפרויקט עם שרת אמיתי

בפרויקט שמתפתח עם שרת אמיתי (FastAPI / אחר), מומלץ לתמוך בשלושה מצבי חיבור:

```ts
type ServerMode = 'real' | 'mock-remote' | 'mock-local';
```

| מצב | מתי להשתמש | URL |
|---|---|---|
| `real` | Production / staging | שרת אמיתי |
| `mock-remote` | Demo למשקיעים | Render mock server |
| `mock-local` | פיתוח יומיומי | localhost:3000 דרך Metro proxy |

ניתן לשלוט במצב דרך environment variable ב-`eas.json`:

```json
{
  "build": {
    "preview-mock": {
      "distribution": "internal",
      "env": { "SERVER_MODE": "mock-remote" }
    },
    "preview-real": {
      "distribution": "internal",
      "env": { "SERVER_MODE": "real" }
    }
  }
}
```
