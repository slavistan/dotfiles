#!/usr/bin/env -S uv run --script
#
# /// script
# requires-python = ">=3.13"
# dependencies = [
#     "pymupdf>=1.28.2",
#     "tabulate>=0.10.0",
# ]
# ///
import argparse
from dataclasses import dataclass
from pathlib import Path
from pprint import pprint
import math
import xml.etree.ElementTree as ET

import pymupdf
from tabulate import tabulate


@dataclass(frozen=True, slots=True)
class OkularAnnotationTool:
    """
    User-defined Okular annotation tool. Read from toolsQuick.xml.
    """

    name: str
    annotation_type: str
    color_rgb: tuple[float, float, float]  # normalized


def parse_okular_tools() -> list[OkularAnnotationTool]:
    result: list[OkularAnnotationTool] = []
    okular_customtools = Path(__file__).resolve().parent / "toolsQuick.xml"
    root = ET.parse(okular_customtools).getroot()
    for tool in root.iter("tool"):
        name =  (tool.attrib["name"])
        annotation_tag = tool.find(".//annotation")
        annotation_type = annotation_tag.attrib["type"] # e.g. Underline, Highlight
        color_hex = annotation_tag.attrib["color"][1:] # e.g. '00ff00'
        color_rgb = tuple(int(color_hex[i*2:i*2+2], 16) / 255 for i in range(3))

        result.append(OkularAnnotationTool(name=name,annotation_type=annotation_type,color_rgb=color_rgb))

    return result


@dataclass(frozen=True, slots=True)
class RawPDFAnnotation:
    id_: str
    type_: str
    page: int
    color_rgb: tuple[float, float, float]  # normalized
    content: str


def find_annotations(pdf_path: Path) -> list[RawPDFAnnotation]:
    result: list[RawPDFAnnotation] = []
    doc = pymupdf.open(pdf_path)
    for pno, page in enumerate(doc):
        for a in page.annots():
            annotation = RawPDFAnnotation(
                id_=a.info["id"],
                page=pno,
                type_=a.type[1],
                color_rgb=tuple(a.colors["stroke"]),
                content=a.info["content"],
            )
            result.append(annotation)
    return result


def match_annotations(
    annotations: list[RawPDFAnnotation],
    tools: list[OkularAnnotationTool],
) -> dict[RawPDFAnnotation, OkularAnnotationTool | None]:
    result: dict[RawPDFAnnotation, OkularAnnotationTool | None] = {}
    for a in annotations:
        result[a] = None
        for t in tools:
            if was_annotation_created_by_tool(a, t):
                result[a] = t
                break
    return result


def was_annotation_created_by_tool(
    annotation: RawPDFAnnotation,
    tool: OkularAnnotationTool,
) -> bool:
    result = (
        annotation.type_ == tool.annotation_type
        and cmp_color_rgb(annotation.color_rgb, tool.color_rgb)
        and annotation.id_.startswith("okular-")
    )
    return result


def cmp_color_rgb(
    a: tuple[float, float, float],
    b: tuple[float, float, float],
) -> bool:
    abs_tol=1/255  # account for rounding errors
    return all(math.isclose(a[i], b[i], abs_tol=abs_tol) for i in range(3))


def print_annotations(pdf_path: Path) -> None:
    tools = parse_okular_tools()
    annotations = find_annotations(pdf_path)
    annot_tool_map = match_annotations(annotations, tools)
    table: list[tuple[str, int, str]] = []
    for annot, tool in annot_tool_map.items():
        name = tool.name if tool is not None else "(unknown)"
        table.append((name, annot.page + 1, annot.type_))
    print(tabulate(table, tablefmt="plain"))


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("pdf_path", type=Path, help="Path to the PDF document")
    args = parser.parse_args()
    print_annotations(args.pdf_path)


# TODO: Was will ich hiermit eigentlich? Actionitems zusammentragen, i.e. alles, was ich nicht verstanden habe.
#       -> --select option für "Highlight".
#       In diesem Zuge sollte ich meine Semantik festzurren: genau die 4 Arten, aus fester Spezifikation die toolsQuick.xml erzeugen, harte Schemata. Macht die Arbeit sehr viel leichter.
#       PDF Annotationen sind laut Claude auch ein abgeschlossenes Set, kann ich also auch statisch parsen, keine `str`.
