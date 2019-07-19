read -p "Do you modify the log location? [y/N] " modify

echo modify=$modify:::

if [ "${modify}" == "y" -o "${modify}" == 'Y' -o "${modify}" == "yes" -o "${modify}" == "Yes" ]; then
echo "abc"	
fi

read -p "Do you add this option? [y/N] " option
echo option=$option;
if [ "${option}" == "y" -o "${option}" == "yes" -o "${option}" == "Y" -o "${option}" == "Yes" ]; then
echo 'right'
fi
