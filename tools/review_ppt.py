from pathlib import Path
import json
import zipfile
import xml.etree.ElementTree as ET


P_NS = {"a": "http://schemas.openxmlformats.org/drawingml/2006/main"}


def extract_texts(xml_bytes):
    root = ET.fromstring(xml_bytes)
    texts = []
    for node in root.findall(".//a:t", P_NS):
        if node.text and node.text.strip():
            texts.append(node.text.strip())
    return texts


def main():
    path = Path(r"C:/Users/KOSMO/Desktop/THE_NEXT_DEBUT.pptx")
    slides = []

    with zipfile.ZipFile(path) as zf:
        slide_names = sorted(
            name
            for name in zf.namelist()
            if name.startswith("ppt/slides/slide") and name.endswith(".xml")
        )
        note_names = {
            name.split("/")[-1].replace("notesSlide", "").replace(".xml", ""): name
            for name in zf.namelist()
            if name.startswith("ppt/notesSlides/notesSlide") and name.endswith(".xml")
        }

        for idx, slide_name in enumerate(slide_names, start=1):
            texts = extract_texts(zf.read(slide_name))
            notes = []
            note_key = str(idx)
            if note_key in note_names:
                notes = extract_texts(zf.read(note_names[note_key]))
            slides.append(
                {
                    "index": idx,
                    "text_count": len(texts),
                    "texts": texts,
                    "notes": notes,
                }
            )

    print(json.dumps({"slide_count": len(slides), "slides": slides}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
