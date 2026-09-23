#!/bin/bash

# ScrcDex - Samsung DeX Experience per Android
# Setup plug and play con notifiche guidate


# 1. RILEVA IL DISPOSITIVO
echo ""
echo "════════════════════════════════════════════════════════"
echo "                  CONTROLLO ADB"
echo "════════════════════════════════════════════════════════"
echo ""

DEVICE=$(adb devices | grep "device$" | awk '{print $1}' | head -1)

if [ -z "$DEVICE" ]; then

    echo "Nessun dispositivo ADB autorizzato trovato."
    echo ""
    echo "Sul telefono fai ESATTAMENTE questo:"
    echo ""
    echo "  • vai in Impostazioni"
    echo "  • vai in Informazioni sul telefono"
    echo "  • cerca Numero build / Versione build"
    echo "  • tocca 4 volte Versione build"
    echo "    per abilitare le Opzioni sviluppatore"
    echo "  • torna nelle Impostazioni"
    echo "  • apri Opzioni sviluppatore"
    echo "  • attiva Debug USB"
    echo ""
    echo "  • collega il telefono al PC"
    echo "  • quando compare la richiesta:"
    echo ""
    echo "       Consenti debug USB?"
    echo ""
    echo "    premi CONSENTI"
    echo ""
    echo "  • se compare l'opzione:"
    echo "       Consenti sempre da questo computer"
    echo ""
    echo "    puoi selezionarla."
    echo ""
    echo "────────────────────────────────────────────────────────"
    echo "Dopo aver completato tutto, torna qui."
    echo "────────────────────────────────────────────────────────"
    echo ""

    read -p "Premi INVIO quando hai autorizzato ADB..."

    echo ""
    echo "Ricontrollo dispositivo ADB..."
    sleep 2

    DEVICE=$(adb devices | grep "device$" | awk '{print $1}' | head -1)

    if [ -z "$DEVICE" ]; then

        echo ""
        echo "ERRORE: nessun dispositivo ADB autorizzato."
        echo ""
        echo "Controlla che:"
        echo "  • il Debug USB sia attivo"
        echo "  • il telefono sia collegato"
        echo "  • tu abbia premuto CONSENTI sulla richiesta ADB"
        echo ""
        echo "Dispositivi rilevati:"
        adb devices
        echo ""

        exit 1

    fi

fi

echo "Dispositivo: $DEVICE"


# 2. CONTROLLO LOG / STATO ADB
echo ""
echo "════════════════════════════════════════════════════════"
echo "                  CONTROLLO LOG ADB"
echo "════════════════════════════════════════════════════════"
echo ""

echo "Controllo connessione ADB..."

ADB_STATE=$(adb -s "$DEVICE" get-state 2>/dev/null | tr -d '\r')

if [ "$ADB_STATE" != "device" ]; then

    echo "Errore: il dispositivo ADB non è nello stato corretto."
    echo ""
    echo "Stato ADB: $ADB_STATE"
    echo ""
    echo "Dispositivi rilevati:"
    adb devices
    echo ""

    exit 1

fi

echo "ADB: OK"
echo "Device: $DEVICE"

echo ""
echo "Controllo informazioni dispositivo..."

MODEL=$(adb -s "$DEVICE" shell getprop ro.product.model 2>/dev/null | tr -d '\r')
ANDROID_VERSION=$(adb -s "$DEVICE" shell getprop ro.build.version.release 2>/dev/null | tr -d '\r')

echo "  Modello: $MODEL"
echo "  Android: $ANDROID_VERSION"

echo ""
echo "Controllo ultimi messaggi di log..."

adb -s "$DEVICE" logcat -d -t 30 2>/dev/null \
    | tail -10 \
    | sed 's/^/  /'

echo ""
echo "Controllo ADB completato."


# 3. SALVA VALORI ORIGINALI
ORIGINAL_SIZE=$(adb -s "$DEVICE" shell wm size | grep "Physical" | awk '{print $3}')
ORIGINAL_DENSITY=$(adb -s "$DEVICE" shell wm density | grep "Physical" | awk '{print $3}')
ORIGINAL_FONT_SCALE=$(adb -s "$DEVICE" shell settings get secure font_scale)

# Salva tastiera/IME predefinito
ORIGINAL_IME=$(adb -s "$DEVICE" shell settings get secure default_input_method | tr -d '\r')

# Salva TUTTA la configurazione originale delle IME
# Questa viene usata per il ripristino finale esatto.
ORIGINAL_ENABLED_IME_RAW=$(adb -s "$DEVICE" shell settings get secure enabled_input_methods | tr -d '\r')

# Android/Samsung può aggiungere metadati dopo ';'
# Per le operazioni ime enable conserviamo solo il vero ID dell'IME.
ORIGINAL_ENABLED_IME=$(echo "$ORIGINAL_ENABLED_IME_RAW" \
    | tr ':' '\n' \
    | cut -d';' -f1 \
    | sed '/^$/d')

# Salva lo stato originale di Google TTS / Voice Input
if adb -s "$DEVICE" shell pm list packages -e 2>/dev/null | grep -q "^package:com.google.android.tts$"; then
    ORIGINAL_GOOGLE_TTS_ENABLED=1
else
    ORIGINAL_GOOGLE_TTS_ENABLED=0
fi

echo ""
echo "Valori originali salvati:"
echo "  Size: $ORIGINAL_SIZE"
echo "  Density: $ORIGINAL_DENSITY"
echo "  Font Scale: $ORIGINAL_FONT_SCALE"
echo "  Tastiera: $ORIGINAL_IME"
echo "  IME abilitati:"
echo "$ORIGINAL_ENABLED_IME" | sed 's/^/    /'
echo "  Google TTS abilitato: $ORIGINAL_GOOGLE_TTS_ENABLED"


# 4. CONTROLLA E INSTALLA TASKBAR
echo ""
echo "Verifica Taskbar..."

TASKBAR_INSTALLED=$(adb -s "$DEVICE" shell pm list packages 2>/dev/null | grep "com.farmerbb.taskbar" | wc -l)

if [ "$TASKBAR_INSTALLED" -lt 1 ]; then

    echo "Taskbar non trovato. Download e installazione..."

    TASKBAR_URL=$(curl -s "https://api.github.com/repos/farmerbb/Taskbar/releases/latest" \
        | grep "browser_download_url" \
        | grep ".apk" \
        | cut -d'"' -f4 \
        | head -1)

    if [ -z "$TASKBAR_URL" ]; then
        echo "Errore: impossibile scaricare Taskbar"
        exit 1
    fi

    curl -L -o /tmp/Taskbar.apk "$TASKBAR_URL" 2>/dev/null

    if [ -s /tmp/Taskbar.apk ]; then

        adb -s "$DEVICE" install -r /tmp/Taskbar.apk

        rm /tmp/Taskbar.apk

        echo "Taskbar installato"

        sleep 2

    else

        echo "Errore nel download di Taskbar"
        exit 1

    fi

else

    echo "Taskbar già installato"

fi


# 5. CONCEDI AUTORIZZAZIONI
echo ""
echo "Configurazione autorizzazioni..."

adb -s "$DEVICE" shell pm grant com.farmerbb.taskbar \
    android.permission.PACKAGE_USAGE_STATS 2>/dev/null || true

adb -s "$DEVICE" shell pm grant com.farmerbb.taskbar \
    android.permission.SYSTEM_ALERT_WINDOW 2>/dev/null || true

echo "Autorizzazioni configurate"


# 6. ABILITA ACCESSIBILITY SERVICE
echo "Configurazione Accessibility Service..."

adb -s "$DEVICE" shell settings put secure enabled_accessibility_services \
    com.farmerbb.taskbar/com.farmerbb.taskbar.accessibility.AccessibilityService \
    2>/dev/null || true

adb -s "$DEVICE" shell settings put secure accessibility_enabled 1

echo "Accessibility Service pronto"


# 7. ABILITA MULTI-WINDOW
echo "Configurazione multi-window..."

adb -s "$DEVICE" shell settings put global enable_freeform_support 1
adb -s "$DEVICE" shell settings put global force_allow_on_external 1


# 8. PASSO 1 - SETUP TASKBAR IMPOSTAZIONI
echo ""
echo "════════════════════════════════════════════════════════"
echo "              PASSO 1 - CONFIGURAZIONE"
echo "════════════════════════════════════════════════════════"
echo ""

echo "Sul telefono:"
echo "  • apri Taskbar"
echo "  • vai su 'Freedom Mode'"
echo "  • attiva tutte le opzioni presenti"
echo "  • vai su 'Advanced'"
echo "  • attiva le prime 2 opzioni"
echo ""

read -p "Premi INVIO quando hai finito..."


# 8. PASSO 2 - ABILITA TASKBAR IN ACCESSIBILITY
echo ""
echo "════════════════════════════════════════"
echo "         PASSO 2 - ACCESSIBILITY"
echo "════════════════════════════════════════"
echo ""

echo "Sul telefono:"
echo "  • vai su 'Recent apps'"
echo "  • attiva faster app switching e show status icons and clock"
echo "  • clicca sull ultima impostazione e dai il permesso"
echo "  • vai in accessibilità"
echo "  • vai su app installate"
echo "  • Cerca e seleziona Taskbar"
echo "  • Attiva il toggle"
echo ""

read -p "Premi INVIO quando fatto..."


# 9. PASSO 3 - ATTIVA TASKBAR NELL'APP
echo ""
echo "════════════════════════════════════════════════════════"
echo "              PASSO 3 - ATTIVAZIONE"
echo "════════════════════════════════════════════════════════"
echo ""

echo "Sul telefono:"
echo "  • torna nell'app Taskbar"
echo "  • vai in Impostazioni Android"
echo "  • vai su Applicazioni"
echo "  • cerca e apri Taskbar"
echo "  • controlla i permessi disponibili"
echo "  • attiva tutto quello che Taskbar richiede"
echo "  • torna nell'app Taskbar"
echo "  • controlla che Taskbar sia ATTIVO"
echo ""

# Riporta Taskbar in primo piano
adb -s "$DEVICE" shell am start -n com.farmerbb.taskbar/.MainActivity

echo ""

read -p "Premi INVIO quando hai finito..."


# 10. AVVIA TASKBAR
echo ""
echo "════════════════════════════════════════════════════════"
echo "                  AVVIO TASKBAR"
echo "════════════════════════════════════════════════════════"
echo ""

echo "Apertura Taskbar..."

adb -s "$DEVICE" shell am start -n com.farmerbb.taskbar/.MainActivity

sleep 2

echo "Eseguo tap 1: 1000 181..."

adb -s "$DEVICE" shell input tap 1000 181

sleep 1

echo "Eseguo tap 2: 2150 160..."

adb -s "$DEVICE" shell input tap 2150 160

sleep 1


# 11. APPLICAZIONE CONFIGURAZIONE DISPLAY
echo ""
echo "════════════════════════════════════════════════════════"
echo "              CONFIGURAZIONE DISPLAY"
echo "════════════════════════════════════════════════════════"
echo ""

echo "Ridimensionamento display..."

adb -s "$DEVICE" shell wm size 2160x3840

adb -s "$DEVICE" shell wm density 400

adb -s "$DEVICE" shell settings put secure font_scale 1.5

echo "Display configurato"

sleep 1


# 12. CAMBIA HOME DA ONEUI A TASKBAR
echo ""
echo "════════════════════════════════════════════════════════"
echo "              CAMBIO HOME SCREEN"
echo "════════════════════════════════════════════════════════"
echo ""

echo "Impostazione Taskbar come home..."

ATTEMPT=1

while [ $ATTEMPT -le 3 ]; do

    RESULT=$(adb -s "$DEVICE" shell cmd package set-home-activity \
        com.farmerbb.taskbar/.MainActivity 2>&1)

    if ! echo "$RESULT" | grep -q "Error"; then

        echo "Taskbar impostato come home"

        break

    else

        if [ $ATTEMPT -lt 3 ]; then

            echo "Tentativo $ATTEMPT fallito, riprovo..."

            sleep 2

        else

            echo "Errore: impossibile impostare Taskbar come home"

            exit 1

        fi

    fi

    ((ATTEMPT++))

done

sleep 2


# 13. DISABILITA TUTTE LE TASTIERE SOFTWARE
echo ""
echo "════════════════════════════════════════════════════════"
echo "              CONFIGURAZIONE TASTIERA"
echo "════════════════════════════════════════════════════════"
echo ""

echo "Tastiera predefinita originale:"
echo "  $ORIGINAL_IME"

echo ""
echo "Recupero tutte le tastiere software abilitate..."

ENABLED_IME_LIST=$(adb -s "$DEVICE" shell ime list -s 2>/dev/null | tr -d '\r')

if [ -z "$ENABLED_IME_LIST" ]; then

    echo "Nessuna tastiera software trovata."

else

    echo ""
    echo "Tastiere software trovate:"
    echo "$ENABLED_IME_LIST"
    echo ""

    while IFS= read -r IME; do

        if [ -z "$IME" ]; then
            continue
        fi

        echo "Disabilito tastiera:"
        echo "  $IME"

        adb -s "$DEVICE" shell ime disable "$IME" 2>/dev/null || true

    done <<< "$ENABLED_IME_LIST"

fi


# Google Voice Input specifico
GOOGLE_VOICE_IME="com.google.android.tts/com.google.android.apps.speech.tts.googletts.settings.asr.voiceime.VoiceInputMethodService"

echo ""
echo "Rimozione esplicita di Google Voice Input..."

CURRENT_ENABLED_IMES=$(adb -s "$DEVICE" shell settings get secure enabled_input_methods \
    | tr -d '\r')

if echo "$CURRENT_ENABLED_IMES" | grep -qF "$GOOGLE_VOICE_IME"; then

    echo "Google Voice Input trovato in enabled_input_methods."

    CLEANED_IMES=$(echo "$CURRENT_ENABLED_IMES" \
        | tr ':' '\n' \
        | grep -vF "$GOOGLE_VOICE_IME" \
        | sed '/^$/d' \
        | paste -sd ':' -)

    adb -s "$DEVICE" shell settings put secure \
        enabled_input_methods "$CLEANED_IMES"

    echo "Google Voice Input rimosso da enabled_input_methods."

else

    echo "Google Voice Input non presente in enabled_input_methods."

fi


# Disabilita anche l'intero pacchetto Google TTS.
echo ""
echo "Blocco Google Voice Input..."

adb -s "$DEVICE" shell pm disable-user --user 0 \
    com.google.android.tts 2>/dev/null || true

echo "Google Voice Input bloccato."


# Controllo finale
echo ""
echo "Controllo tastiere rimaste abilitate..."

REMAINING_IME=$(adb -s "$DEVICE" shell ime list -s 2>/dev/null | tr -d '\r')

FINAL_ENABLED_IMES=$(adb -s "$DEVICE" shell settings get secure enabled_input_methods \
    | tr -d '\r')

echo ""

if [ -z "$REMAINING_IME" ]; then

    echo "ime list -s: nessuna tastiera software abilitata."

else

    echo "ime list -s riporta:"
    echo "$REMAINING_IME"

fi

echo ""

if [ -z "$FINAL_ENABLED_IMES" ] || [ "$FINAL_ENABLED_IMES" = "null" ]; then

    echo "enabled_input_methods: nessuna IME registrata."

else

    echo "enabled_input_methods:"
    echo "$FINAL_ENABLED_IMES"

fi

echo ""

if echo "$REMAINING_IME" | grep -qF "$GOOGLE_VOICE_IME" || \
   echo "$FINAL_ENABLED_IMES" | grep -qF "$GOOGLE_VOICE_IME"; then

    echo "ATTENZIONE: Google Voice Input risulta ancora presente."

else

    echo "Google Voice Input NON risulta più abilitato."

fi

echo ""
echo "La tastiera fisica rimane utilizzabile."
echo "Configurazione tastiera completata."

sleep 1


# 14. AVVIA SCRCOPY
echo ""
echo "════════════════════════════════════════════════════════"
echo "                  AVVIO SCRCDEX"
echo "════════════════════════════════════════════════════════"
echo ""

echo "Avvio scrcpy..."

./scrcpy \
    --video-bit-rate=25M \
    --max-fps=60 \
    --video-codec=h265 \
    --turn-screen-off


# 15. RIPRISTINA TUTTO
echo ""
echo "════════════════════════════════════════════════════════"
echo "              RIPRISTINO CONFIGURAZIONE"
echo "════════════════════════════════════════════════════════"
echo ""

echo "Ripristino Accessibility..."

adb -s "$DEVICE" shell settings put secure \
    enabled_accessibility_services "" 2>/dev/null || true

adb -s "$DEVICE" shell settings put secure \
    accessibility_enabled 0


echo "Ripristino multi-window..."

adb -s "$DEVICE" shell settings put global enable_freeform_support 0

adb -s "$DEVICE" shell settings put global force_allow_on_external 0


echo "Ripristino Home Screen OneUI..."

adb -s "$DEVICE" shell pm enable \
    com.samsung.android.app.launcher 2>/dev/null || true

adb -s "$DEVICE" shell cmd package set-home-activity \
    com.sec.android.app.launcher/com.android.launcher3.Launcher \
    2>/dev/null || true


echo "Ripristino display..."

adb -s "$DEVICE" shell wm size "$ORIGINAL_SIZE" 2>/dev/null || true

adb -s "$DEVICE" shell wm density "$ORIGINAL_DENSITY" 2>/dev/null || true

adb -s "$DEVICE" shell settings put secure font_scale \
    "$ORIGINAL_FONT_SCALE" 2>/dev/null || true


# 16. RIPRISTINA TUTTE LE TASTIERE ORIGINALI
echo ""
echo "════════════════════════════════════════════════════════"
echo "              RIPRISTINO TASTIERA"
echo "════════════════════════════════════════════════════════"
echo ""

echo "Riabilito le tastiere presenti prima di ScrcDex..."

if [ -n "$ORIGINAL_ENABLED_IME" ] && [ "$ORIGINAL_ENABLED_IME" != "null" ]; then

    while IFS= read -r IME; do

        if [ -z "$IME" ]; then
            continue
        fi

        echo "Riabilito:"
        echo "  $IME"

        adb -s "$DEVICE" shell ime enable \
            "$IME" 2>/dev/null || true

    done <<< "$ORIGINAL_ENABLED_IME"

else

    echo "Nessun elenco IME originale disponibile."

fi


# Ripristina ESATTAMENTE la lista enabled_input_methods originale.
if [ -n "$ORIGINAL_ENABLED_IME_RAW" ] && \
   [ "$ORIGINAL_ENABLED_IME_RAW" != "null" ]; then

    echo ""
    echo "Ripristino lista IME originale..."

    adb -s "$DEVICE" shell settings put secure \
        enabled_input_methods "$ORIGINAL_ENABLED_IME_RAW" \
        2>/dev/null || true

fi


# Ripristina la tastiera predefinita originale
if [ -n "$ORIGINAL_IME" ] && [ "$ORIGINAL_IME" != "null" ]; then

    echo ""
    echo "Ripristino tastiera predefinita:"
    echo "  $ORIGINAL_IME"

    adb -s "$DEVICE" shell ime enable \
        "$ORIGINAL_IME" 2>/dev/null || true

    adb -s "$DEVICE" shell ime set \
        "$ORIGINAL_IME" 2>/dev/null || \
    adb -s "$DEVICE" shell settings put secure \
        default_input_method "$ORIGINAL_IME" 2>/dev/null || true

    echo "Tastiera originale ripristinata."

else

    echo "Tastiera originale non rilevata."

fi


# Ripristina Google TTS solo se era abilitato all'avvio
if [ "$ORIGINAL_GOOGLE_TTS_ENABLED" -eq 1 ]; then

    echo ""
    echo "Riabilito Google TTS / Voice Input..."

    adb -s "$DEVICE" shell pm enable \
        com.google.android.tts 2>/dev/null || true

    echo "Google TTS / Voice Input ripristinato."

else

    echo ""
    echo "Google TTS era disabilitato all'avvio."
    echo "Rimane disabilitato."

fi


echo ""
echo "Chiusura Taskbar..."

adb -s "$DEVICE" shell am force-stop \
    com.farmerbb.taskbar 2>/dev/null || true


echo ""
echo "════════════════════════════════════════════════════════"
echo "          CONFIGURAZIONE RIPRISTINATA"
echo "════════════════════════════════════════════════════════"
echo ""

echo "ScrcDex terminato."
