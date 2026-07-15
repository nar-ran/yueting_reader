# YuèTīng (阅听) — Lector y Oyente de Chino ![Estado](https://img.shields.io/badge/Estado-Finalizado-green)

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white) 
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Hive](https://img.shields.io/badge/Hive-NoSQL-F2C94C?style=for-the-badge&logo=hive&logoColor=black)
![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)

**YuèTīng (阅听)** es un asistente universal, limpio e intuitivo desarrollado con Flutter para el aprendizaje de chino mandarín. Permite a los usuarios importar textos (como letras de canciones o noticias), segmentarlos automáticamente en palabras con marcas de tono Pinyin (Ruby text) alineadas verticalmente, realizar consultas rápidas en un diccionario offline (CC-CEDICT) y escuchar lecturas sincronizadas palabra por palabra con múltiples motores TTS locales y en la nube.

---

## 🚀 Funcionalidades Principales

*   **Segmentación y Alineación (Pinyin):**
    *   Algoritmo Max Match personalizado para segmentar caracteres chinos en palabras con fallbacks robustos.
    *   Disposición fluida tipo `Wrap` que coloca el Pinyin verticalmente alineado sobre cada carácter Hanzi, evitando recortes en pantallas pequeñas.
*   **Diccionario Offline CC-CEDICT:**
    *   Carga inicial asíncrona de los datos binarios de traducción de MDBG CC-CEDICT.
    *   Consultas instantáneas de definiciones, variantes de escritura tradicional/simplificada e integración con traducciones dynamically al español en tiempo real.
*   **Biblioteca y Progreso Persistente:**
    *   Carga persistente de textos importados mediante almacenamiento local NoSQL con Hive.
    *   Cálculo y guardado en tiempo real del progreso de lectura (ej. *55% leído*) conforme avanza el audio o se pulsan palabras.
    *   Gestión de biblioteca con buscador integrado, renombrado dinámico y borrado gestual (swipe-to-delete).
*   **Sintetizador y Sincronización de Audio:**
    *   *Google System TTS (Local):* Reproducción nativa offline de alta velocidad con resaltado activo de palabra color ámbar.
    *   *Microsoft Edge TTS (Cloud):* Acceso gratuito a síntesis de voz neuronal de alta fidelidad sin requerir API Key.
    *   *Microsoft Azure & OpenAI Speech (Cloud):* APIs premium sincronizadas mediante un estimador lineal temporal basado en la longitud de caracteres.
*   **Temas Cromáticos Personalizados (11 Temas):** Acordeón colapsable con burbujas indicadoras de color. Incluye **Clásico Salvia** (coherente con la paleta de colores del conejo del icono), **Clásico Violeta** y 9 paletas tipo acuarela de nubes de alto contraste.
*   **Localización e Internacionalización (Soporte Bilingüe):**
    *   Soporte completo de traducción de interfaz de usuario localizados nativamente en **Español** e **Inglés**.
    *   Cambio en caliente (hot swap) de todos los menús, diálogos, etiquetas y mensajes de la aplicación mediante la clase `AppLocalizations` de Flutter de manera reactiva y sin necesidad de reiniciar.

---

## 🛠️ Tecnologías Utilizadas

### Frontend / Cliente Móvil

*   **Framework:** [Flutter 3.x](https://flutter.dev/) (Multiplataforma)
*   **Lenguaje:** [Dart](https://dart.dev/)
*   **Base de Datos Local:** [Hive NoSQL](https://pub.dev/packages/hive) (para almacenamiento de lecturas y configuración)
*   **Enrutamiento y Estado:** Gestión de estado reactiva integrada nativamente con `setState` y controladores especializados de base de datos.
*   **Síntesis de Voz Local:** [flutter_tts](https://pub.dev/packages/flutter_tts)
*   **Peticiones HTTP:** Cliente REST de `HttpClient` nativo para llamadas asíncronas de APIs en la nube.
*   **Estilos:** Custom `ThemeExtension` de Flutter para inyectar y alternar dinámicamente entre las 11 paletas cromáticas de la app.

---

## 📝 Estructura de la Base de Datos Local (Hive)

La persistencia de la aplicación se gestiona de forma local y segura en el dispositivo móvil del usuario mediante cajas (`Boxes`) de Hive.

### Caja: `reading_entries` (Adaptador de Tipo: `ReadingEntry`)

| Campo | Tipo | Clave Hive (`@HiveField`) | Descripción |
| :--- | :--- | :--- | :--- |
| `id` | `String` | `0` | Identificador único UUID de la lectura (Clave primaria del box). |
| `title` | `String` | `1` | Título del texto importado o creado por el usuario. |
| `text` | `String` | `2` | Contenido del texto original en caracteres chinos (Hanzi). |
| `dateCreated` | `DateTime` | `3` | Fecha y hora de importación del registro. |
| `dateLastOpened` | `DateTime` | `4` | Marca de tiempo del último acceso (usado para la sección "Continuar Leyendo"). |
| `progress` | `double?` | `5` | Porcentaje de avance de la lectura (valor decimal entre `0.0` y `1.0`). |

### Caja: `settings`

Esta caja almacena configuraciones generales en formato Clave-Valor (`Key-Value`).

| Clave (Key) | Tipo | Valor por Defecto | Descripción |
| :--- | :--- | :--- | :--- |
| `active_theme` | `String` | `'classic'` | Nombre del tema visual seleccionado (ej. `classic`, `violet`, `earthy`). |
| `voice_engine` | `String` | `'google'` | Motor de síntesis de voz configurado (`google`, `edge`, `azure`, `openai`). |
| `voice_language` | `String` | `'zh-CN'` | Idioma de síntesis de voz configurado (`zh-CN`, `zh-TW`, `zh-HK`). |
| `font_size_multiplier` | `double` | `1.0` | Multiplicador de escala para el texto del lector (rango de `0.8` a `1.6`). |

---

## 🏁 Puesta en Marcha (Desarrollo Local)

Sigue estos pasos para compilar y ejecutar el proyecto en tu máquina local.

1.  **Clonar el repositorio:**
    ```bash
    git clone https://github.com/nar-ran/yueting-reader.git
    cd yueting-reader/yueting_reader
    ```

2.  **Obtener las dependencias de Flutter:**
    ```bash
    flutter pub get
    ```

3.  **Generar adaptadores Hive y recursos de idioma (l10n):**
    ```bash
    flutter pub run build_runner build --delete-conflicting-outputs
    flutter gen-l10n
    ```

4.  **Ejecutar la aplicación en modo desarrollo:**
    ```bash
    flutter run
    ```

---

## 📜 Licencia

MIT License

Puedes utilizar este proyecto libremente para fines personales, educativos o comerciales.
