// import * as pip from "../src/package_manager/pip";
// import { pip3Packages } from "../src/package_manager/pip";
import { parse } from "@babel/parser";
import traverse from "@babel/traverse";
import * as t from "@babel/types";
import * as fs from "fs";
import fetch from "node-fetch";

const task = async () => {
  const type: string = "clone-typescript";

  // Get code
  let code: string = "";
  if (type == "fetch-typescript") {
    const content = await fetch(
      "https://raw.githubusercontent.com/ros-tooling/setup-ros/master/src/package_manager/pip.ts"
    );
    code = await content.text();
  } else if (type == "clone-typescript") {
    code = fs.readFileSync("./setup-ros/src/package_manager/pip.ts", "utf-8");
  } else if (type == "clone-javascript") {
    code = fs.readFileSync("./setup-ros/dist/index.js", "utf-8");
  }

  // Parse code
  const ast = parse(code, {
    sourceType: "module",
    plugins: ["typescript"],
  });

  // Get pip3 packages
  let pip3Packages: string[] = [];
  traverse(ast, {
    enter(path) {
      if (path.isVariableDeclarator() && (path.node.id as t.Identifier).name == "pip3Packages") {
        const init = path.node.init as t.ArrayExpression;
        for (const elem of init.elements) {
          pip3Packages.push((elem as t.StringLiteral).value);
        }
      }
    },
  });

  // Create requirements.txt
  const f = fs.createWriteStream("./requirements.txt");
  for (const pkg of pip3Packages) {
    f.write(`${pkg}\n`);
  }
};

task();
