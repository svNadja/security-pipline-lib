mkdir -p reports/bandit
python3 -m bandit -r . -x ./.venv,./reports -f json -o reports/bandit/bandit-report.json
