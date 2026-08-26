"""Create a publication-ready Figure 3 and place it in a copy of the paper."""

from __future__ import annotations

from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo

import matplotlib.pyplot as plt
from lxml import etree
from matplotlib.patches import FancyArrowPatch, FancyBboxPatch


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SOURCE_DOCX = PROJECT_ROOT / "Smart_Inverter_IEEE33_Complete_Paper.docx"
OUTPUT_DOCX = PROJECT_ROOT / "Smart_Inverter_IEEE33_Complete_Paper_IEEE_DoubleColumn.docx"
OUTPUT_PNG = (
    PROJECT_ROOT
    / "results"
    / "figures"
    / "figure3_matlab_simulink_integration_professional.png"
)

OLD_CAPTION = (
    "Fig. 3. MATLAB-Simulink integration used in the project. Simulink supports "
    "visualization and result replay, while MATLAB produces the numerical QSTS results."
)
NEW_CAPTION = (
    "Fig. 3. Data flow between the MATLAB QSTS pipeline and the Simulink results "
    "viewer. MATLAB executes controller comparison, offline PSO, load flow, metric "
    "calculation, and reporting; Simulink loads saved signals only for visualization "
    "and replay."
)

AUTHOR_PLACEHOLDER = "Author name(s) and affiliation(s) to be added"
AUTHOR_BLOCK_XML = (
    "REAJ UDDIN HEMAL</w:t>"
    "<w:br/><w:t>Student Number: A00046863</w:t>"
    "<w:br/><w:t>Course Code: TU207</w:t>"
    "<w:br/><w:t>Department: School of Electrical and Electronic Engineering"
)

NAVY = "#17365D"
BLUE = "#DCEAF7"
BLUE_DARK = "#2B6F9E"
TEAL = "#DDF2EF"
TEAL_DARK = "#287C72"
GOLD = "#FFF0C7"
GOLD_DARK = "#B87800"
GREEN = "#E4F1DC"
GREEN_DARK = "#4D7F3B"
GRAY = "#F3F5F7"
GRAY_DARK = "#5D6772"
WHITE = "#FFFFFF"


def rounded_box(
    ax,
    x: float,
    y: float,
    width: float,
    height: float,
    *,
    face: str,
    edge: str,
    radius: float = 0.012,
    linewidth: float = 0.9,
    zorder: int = 2,
) -> FancyBboxPatch:
    patch = FancyBboxPatch(
        (x, y),
        width,
        height,
        boxstyle=f"round,pad=0.006,rounding_size={radius}",
        facecolor=face,
        edgecolor=edge,
        linewidth=linewidth,
        transform=ax.transAxes,
        clip_on=False,
        zorder=zorder,
    )
    ax.add_patch(patch)
    return patch


def arrow(
    ax,
    start: tuple[float, float],
    end: tuple[float, float],
    *,
    color: str = NAVY,
    dashed: bool = False,
    curve: float = 0.0,
    linewidth: float = 0.9,
    zorder: int = 3,
) -> None:
    patch = FancyArrowPatch(
        start,
        end,
        arrowstyle="-|>",
        mutation_scale=7.0,
        linewidth=linewidth,
        linestyle=(0, (3.0, 2.0)) if dashed else "solid",
        color=color,
        connectionstyle=f"arc3,rad={curve}",
        transform=ax.transAxes,
        clip_on=False,
        zorder=zorder,
    )
    ax.add_patch(patch)


def label(
    ax,
    x: float,
    y: float,
    text: str,
    *,
    size: float,
    color: str = NAVY,
    weight: str = "normal",
    ha: str = "center",
    va: str = "center",
    linespacing: float = 1.05,
    zorder: int = 4,
) -> None:
    ax.text(
        x,
        y,
        text,
        fontsize=size,
        color=color,
        fontweight=weight,
        fontfamily="DejaVu Sans",
        ha=ha,
        va=va,
        linespacing=linespacing,
        transform=ax.transAxes,
        zorder=zorder,
    )


def create_diagram(output_file: Path) -> None:
    output_file.parent.mkdir(parents=True, exist_ok=True)

    # Match the original Word figure's 3.15 x 3.54 inch footprint. This keeps
    # text legible in the paper's two-column layout and avoids pagination changes.
    fig, ax = plt.subplots(figsize=(3.15, 3.54), dpi=400)
    fig.patch.set_facecolor(WHITE)
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.axis("off")
    fig.subplots_adjust(left=0.025, right=0.975, top=0.985, bottom=0.025)

    # Restrained grayscale palette for print and IEEE-style presentation.
    ink = "#202428"
    dark = "#3A3F44"
    mid = "#6B7279"
    line = "#555C63"
    light = "#F1F2F3"
    very_light = "#FAFAFA"

    # MATLAB numerical pipeline container.
    rounded_box(
        ax,
        0.025,
        0.370,
        0.95,
        0.600,
        face=very_light,
        edge=line,
        radius=0.012,
        linewidth=1.0,
        zorder=1,
    )
    rounded_box(
        ax,
        0.025,
        0.912,
        0.95,
        0.058,
        face=dark,
        edge=dark,
        radius=0.010,
        linewidth=0.0,
        zorder=2,
    )
    label(
        ax,
        0.5,
        0.941,
        "MATLAB NUMERICAL QSTS PIPELINE",
        size=7.3,
        color=WHITE,
        weight="bold",
    )

    # A single vertical process path prevents connector crossings.
    rounded_box(ax, 0.10, 0.812, 0.72, 0.070, face=WHITE, edge=line, radius=0.007)
    label(ax, 0.46, 0.858, "Feeder and scenario inputs", size=6.5, color=ink, weight="bold")
    label(
        ax,
        0.46,
        0.830,
        "IEEE 33-bus data  |  24-h load/PV  |  penetration cases",
        size=4.85,
        color=mid,
    )

    rounded_box(ax, 0.10, 0.675, 0.72, 0.086, face=light, edge=line, radius=0.007)
    label(ax, 0.46, 0.736, "Control selection and parameter tuning", size=6.15, color=ink, weight="bold")
    label(
        ax,
        0.46,
        0.703,
        "No control | Volt-VAR | Volt-Watt | Hybrid\nOffline PSO tunes nine hybrid-curve parameters",
        size=4.8,
        color=mid,
    )

    rounded_box(ax, 0.10, 0.545, 0.72, 0.084, face=WHITE, edge=line, radius=0.007)
    label(ax, 0.46, 0.604, "QSTS load-flow engine", size=6.4, color=ink, weight="bold")
    label(
        ax,
        0.46,
        0.573,
        "24-h backward/forward sweep  |  inverter capability limits",
        size=4.75,
        color=mid,
    )

    rounded_box(ax, 0.10, 0.415, 0.72, 0.084, face=light, edge=line, radius=0.007)
    label(ax, 0.46, 0.474, "Performance assessment", size=6.4, color=ink, weight="bold")
    label(
        ax,
        0.46,
        0.443,
        "voltage limits | losses | curtailment | hosting capacity",
        size=4.75,
        color=mid,
    )

    # Main arrows terminate in the whitespace between boxes.
    arrow(ax, (0.46, 0.812), (0.46, 0.766), color=ink, linewidth=0.8)
    arrow(ax, (0.46, 0.675), (0.46, 0.634), color=ink, linewidth=0.8)
    arrow(ax, (0.46, 0.545), (0.46, 0.504), color=ink, linewidth=0.8)

    # Offline PSO objective feedback is isolated in the right margin and does
    # not cross any box, label, or forward-flow connector.
    ax.plot(
        [0.82, 0.90, 0.90],
        [0.457, 0.457, 0.718],
        color=line,
        linewidth=0.75,
        linestyle=(0, (3.0, 2.0)),
        transform=ax.transAxes,
        zorder=3,
    )
    arrow(ax, (0.90, 0.718), (0.825, 0.718), color=line, dashed=True, linewidth=0.75)
    ax.text(
        0.935,
        0.587,
        "offline PSO objective feedback",
        fontsize=4.25,
        color=mid,
        fontfamily="DejaVu Sans",
        ha="center",
        va="center",
        rotation=90,
        transform=ax.transAxes,
        zorder=4,
    )

    # Persistence boundary: numerical results leave MATLAB through files.
    rounded_box(ax, 0.14, 0.350, 0.72, 0.050, face=WHITE, edge=line, radius=0.007)
    label(
        ax,
        0.50,
        0.375,
        "SAVED NUMERICAL RESULTS  (.MAT / .CSV)",
        size=5.75,
        weight="bold",
        color=ink,
    )
    arrow(ax, (0.46, 0.415), (0.46, 0.404), color=ink, linewidth=0.8)

    # Saved results feed two independent consumers through orthogonal branches.
    rounded_box(ax, 0.040, 0.120, 0.445, 0.150, face=WHITE, edge=line, radius=0.008)
    rounded_box(ax, 0.515, 0.120, 0.445, 0.150, face=WHITE, edge=line, radius=0.008)
    rounded_box(
        ax,
        0.040,
        0.230,
        0.445,
        0.040,
        face=dark,
        edge=dark,
        radius=0.006,
        linewidth=0.0,
    )
    rounded_box(
        ax,
        0.515,
        0.230,
        0.445,
        0.040,
        face=dark,
        edge=dark,
        radius=0.006,
        linewidth=0.0,
    )
    label(ax, 0.2625, 0.250, "SIMULINK RESULTS VIEWER", size=5.35, color=WHITE, weight="bold")
    label(ax, 0.7375, 0.250, "MATLAB REPORTING", size=5.6, color=WHITE, weight="bold")
    label(
        ax,
        0.2625,
        0.174,
        "Reads saved signals\nScopes and dashboards\nVisualization and replay only",
        size=4.8,
        color=ink,
        linespacing=1.14,
    )
    label(
        ax,
        0.7375,
        0.174,
        "Publication figures and tables\nController comparisons\nHosting-capacity and PSO summaries",
        size=4.55,
        color=ink,
        linespacing=1.14,
    )

    ax.plot([0.50, 0.50], [0.350, 0.310], color=ink, linewidth=0.8, transform=ax.transAxes)
    ax.plot([0.2625, 0.7375], [0.310, 0.310], color=ink, linewidth=0.8, transform=ax.transAxes)
    ax.scatter([0.50], [0.310], s=6, color=ink, transform=ax.transAxes, zorder=4)
    arrow(ax, (0.2625, 0.310), (0.2625, 0.275), color=ink, linewidth=0.8)
    arrow(ax, (0.7375, 0.310), (0.7375, 0.275), color=ink, linewidth=0.8)

    rounded_box(ax, 0.125, 0.035, 0.75, 0.043, face=very_light, edge="#A4A9AE", radius=0.006, linewidth=0.6)
    label(
        ax,
        0.5,
        0.0565,
        "No switching-level or EMT inverter simulation",
        size=5.1,
        color=mid,
        weight="bold",
    )

    fig.savefig(
        output_file,
        dpi=400,
        facecolor=WHITE,
        bbox_inches=None,
        pad_inches=0,
        metadata={"Software": "Matplotlib", "Title": "MATLAB-Simulink QSTS data flow"},
    )
    plt.close(fig)


def move_two_column_boundary(document_xml: bytes) -> tuple[bytes, int]:
    """Start the existing two-column section immediately after the author block."""

    word_ns = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
    ns = {"w": word_ns}
    root = etree.fromstring(document_xml)
    paragraphs = root.xpath("./w:body/w:p", namespaces=ns)

    author_paragraph = None
    source_paragraph = None
    source_section = None

    for paragraph in paragraphs:
        text_value = "".join(paragraph.xpath(".//w:t/text()", namespaces=ns))
        if "Student Number: A00046863" in text_value or AUTHOR_PLACEHOLDER in text_value:
            author_paragraph = paragraph

        section_nodes = paragraph.xpath("./w:pPr/w:sectPr", namespaces=ns)
        if section_nodes:
            source_paragraph = paragraph
            source_section = section_nodes[0]

    if author_paragraph is None or source_paragraph is None or source_section is None:
        return document_xml, 0

    source_properties = source_paragraph.find(f"{{{word_ns}}}pPr")
    if source_properties is None:
        return document_xml, 0
    source_properties.remove(source_section)

    author_properties = author_paragraph.find(f"{{{word_ns}}}pPr")
    if author_properties is None:
        author_properties = etree.Element(f"{{{word_ns}}}pPr")
        author_paragraph.insert(0, author_properties)

    # Section properties must be the final element of w:pPr.
    author_properties.append(source_section)
    return (
        etree.tostring(
            root,
            encoding="UTF-8",
            xml_declaration=True,
            standalone=True,
        ),
        1,
    )


def replace_figure_and_caption(source: Path, destination: Path, figure: Path) -> None:
    old_caption_bytes = OLD_CAPTION.encode("utf-8")
    new_caption_bytes = NEW_CAPTION.encode("utf-8")
    author_placeholder_bytes = AUTHOR_PLACEHOLDER.encode("utf-8")
    author_block_bytes = AUTHOR_BLOCK_XML.encode("utf-8")
    caption_replacements = 0
    author_replacements = 0
    section_boundary_moves = 0

    with ZipFile(source, "r") as src, ZipFile(destination, "w") as dst:
        for item in src.infolist():
            data = src.read(item.filename)

            if item.filename == "word/media/image3.png":
                data = figure.read_bytes()
            elif item.filename == "word/document.xml":
                caption_replacements = data.count(old_caption_bytes)
                data = data.replace(old_caption_bytes, new_caption_bytes)
                author_replacements = data.count(author_placeholder_bytes)
                data = data.replace(author_placeholder_bytes, author_block_bytes)
                data, section_boundary_moves = move_two_column_boundary(data)

            copied = ZipInfo(item.filename, date_time=item.date_time)
            copied.compress_type = ZIP_DEFLATED
            copied.comment = item.comment
            copied.extra = item.extra
            copied.internal_attr = item.internal_attr
            copied.external_attr = item.external_attr
            copied.create_system = item.create_system
            dst.writestr(copied, data)

    if caption_replacements != 1:
        destination.unlink(missing_ok=True)
        raise RuntimeError(
            f"Expected one Figure 3 caption, found {caption_replacements}; no paper was produced."
        )
    if author_replacements != 1:
        destination.unlink(missing_ok=True)
        raise RuntimeError(
            f"Expected one author placeholder, found {author_replacements}; no paper was produced."
        )
    if section_boundary_moves != 1:
        destination.unlink(missing_ok=True)
        raise RuntimeError(
            "Could not move the two-column section boundary after the author block; "
            "no paper was produced."
        )


def main() -> None:
    if not SOURCE_DOCX.exists():
        raise FileNotFoundError(SOURCE_DOCX)

    create_diagram(OUTPUT_PNG)
    replace_figure_and_caption(SOURCE_DOCX, OUTPUT_DOCX, OUTPUT_PNG)
    print(f"Created diagram: {OUTPUT_PNG}")
    print(f"Created revised paper: {OUTPUT_DOCX}")


if __name__ == "__main__":
    main()
