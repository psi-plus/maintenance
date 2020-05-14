#!/usr/bin/env python3
# The script accepts metadata json files (all of them) from plugins
# and generates translations files in the current directory

import sys
import os
import json

languages = ["ru", "de"]
translations = dict((k, {}) for k in languages)


def parse_translations(filename, js):
    translatable = ["name"]
    sources = {}
    trans = {}

    for full_prop, value in js.items():
        parts = full_prop.split(":")
        if parts[0] not in translatable:
            continue
        if len(parts) == 2:
            prop, lang = parts
            trans[prop] = trans.get(prop, {})
            trans[prop][lang] = value
        else:
            sources[parts[0]] = value

    context = "meta:" + os.path.split(filename)[1][:-5]
    for prop, source in sources.items():
        for lang in languages:
            translation = trans.get(prop, {}).get(lang, "")
            if context not in translations[lang]:
                translations[lang][context] = {}
            translations[lang][context][source] = (filename, 0, translation)


def dump_ts(out, contexts):
    for context, trans in contexts.items():
        messages = []
        for source, (filename, line, translation) in trans.items():
            messages.append(f"""    <message>
        <location filename="{filename}" line="{line}"/>
        <source>{source}</source>
        <translation>{translation}</translation>
    </message>""")

        messages = "\n".join(messages)
        out.write(f"""<context>
    <name>{context}</name>
{messages}
</context>""")


for fname in sys.argv[1:]:
    with open(fname) as f:
        js = json.load(f)
        parse_translations(fname, js)

for lang, trs in translations.items():
    with open("plugin_meta_" + lang + ".ts", "w") as f:
        dump_ts(f, trs)
