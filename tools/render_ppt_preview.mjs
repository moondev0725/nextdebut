import fs from "node:fs/promises";
import path from "node:path";
import { FileBlob, PresentationFile } from "@oai/artifact-tool";

const input = "C:/Users/KOSMO/Desktop/THE_NEXT_DEBUT.pptx";
const outDir = "C:/Users/KOSMO/Desktop/NEXTDEBUT/tmp/ppt_review";

async function main() {
  await fs.mkdir(outDir, { recursive: true });
  const blob = await FileBlob.load(input);
  const presentation = await PresentationFile.importPptx(blob);

  for (let i = 0; i < presentation.slides.count; i += 1) {
    const slide = presentation.slides.getItem(i);
    const image = await presentation.export({ slide, format: "png", scale: 1 });
    const filename = path.join(outDir, `slide-${String(i + 1).padStart(2, "0")}.png`);
    if (image?.save) {
      await image.save(filename);
    } else if (image instanceof Uint8Array) {
      await fs.writeFile(filename, image);
    } else if (image instanceof ArrayBuffer) {
      await fs.writeFile(filename, Buffer.from(image));
    } else if (image?.buffer) {
      await fs.writeFile(filename, Buffer.from(image.buffer));
    } else if (typeof image?.arrayBuffer === "function") {
      const bytes = await image.arrayBuffer();
      await fs.writeFile(filename, Buffer.from(bytes));
    } else {
      console.log(
        JSON.stringify({
          type: typeof image,
          constructor: image?.constructor?.name,
          keys: Object.keys(image || {}),
        }),
      );
      throw new Error("Unsupported export result");
    }
    console.log(filename);
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
