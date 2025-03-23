# Trackord

### Environment Setup:

#### Auto-generate l10n files on saving the .arb files
- Install [pucelle.run-on-save](https://marketplace.cursorapi.com/items?itemName=pucelle.run-on-save)
- Copy the following code into editor's settings.json
    ```json
    "runOnSave.commands": [
            {
                "match": ".arb",
                "command": "flutter gen-l10n",
                "runIn": "terminal",
            },
        ],
    "runOnSave.defaultRunIn": "terminal",
    "runOnSave.onlyRunOnManualSave": true,
    ```
