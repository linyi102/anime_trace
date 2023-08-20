echo "Select the platform to build:"
echo "[1]: Android"
echo "[2]: Windows"
echo "[3]: All"
echo -n "Please choose one (or "q" to quit): "
read -n 1 choice
echo ""

case $choice in
1)
    echo "Building Android..."
    flutter build apk --split-per-abi
    ;;
2)
    echo "Building Windows..."
    flutter build windows
    ;;
3)
    echo "Building All..."
    flutter build apk --split-per-abi
    flutter build windows
    ;;
q)
    exit 0
    ;;

esac
