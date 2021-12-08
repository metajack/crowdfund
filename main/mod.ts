// Copyright (c) The Diem Core Contributors
// SPDX-License-Identifier: Apache-2.0

// deno-lint-ignore-file no-explicit-any
// deno-lint-ignore-file ban-types

import * as DiemHelpers from "./helpers.ts";
import {
  consoleContext,
  defaultUserContext,
  UserContext,
} from "./context.ts";
import * as devapi from "./devapi.ts";
import * as mv from "./move.ts";
import { green } from "https://deno.land/x/nanocolors@0.1.12/mod.ts";

await printWelcome();

function highlight(content: string) {
  return green(content);
}

export async function printWelcome() {
  console.log(`Loading Project ${highlight(consoleContext.projectPath)}`);
  console.log(
    `Default Account Address ${highlight(defaultUserContext.address)}`,
  );
  console.log(
    `"helpers", "devapi", "context", "main", "codegen", "help" top level objects available`,
  );
  console.log(`Run "help" for more information on top level objects`);
  console.log(
    `Connecting to ${consoleContext.networkName} at ${
      highlight(consoleContext.client.baseUrl)
    }`,
  );
  console.log(await devapi.ledgerInfo());
  console.log();
}

export async function creator_createProject(
  goal: number,
  end_time_secs: number,
  sender?: UserContext,
  moduleAddress?: string,
) {
  return await invokeScriptFunction(
    "TestProjectCreate::create_project",
    [`0x1::XUS::XUS`],
    [mv.U64(`${goal}`), mv.U64(`${end_time_secs}`)],
    sender,
    moduleAddress,
  );
}

export async function cancelProject(
  projectType: string,
  goal: number,
  end_time_secs: number,
  sender?: UserContext,
  moduleAddress?: string,
) {
  return await invokeScriptFunction(
    "Crowdfund::cancel_project",
    [`${projectType}`, "0x1::XUS::XUS"],
    [mv.Ascii("canceled")],
    sender,
    moduleAddress,
  );
}

export async function claimProject(
  projectType: string,
  sender?: UserContext,
  moduleAddress?: string,
) {
  return await invokeScriptFunction(
    "Crowdfund::claim_project",
    [`${projectType}`, "0x1::XUS::XUS"],
    [],
    sender,
    moduleAddress,
  );
}

export async function pledge(
  projectType: string,
  projectAddress: string,
  amount: number,
  sender?: UserContext,
  moduleAddress?: string,
) {
  return await invokeScriptFunction(
    "Crowdfund::pledge",
    [`${projectType}`, "0x1::XUS::XUS"],
    [mv.Address(projectAddress), mv.U64(`${amount}`)],
    sender,
    moduleAddress,
  );
}

export async function cancelPledge(
  projectType: string,
  sender?: UserContext,
  moduleAddress?: string,
) {
  return await invokeScriptFunction(
    "Crowdfund::pledge",
    [`${projectType}`, "0x1::XUS::XUS"],
    [],
    sender,
    moduleAddress,
  );
}

export async function current_secs() {
  return Math.floor(Number((await devapi.ledgerInfo()).ledger_timestamp) / 1000000);
}

async function invokeScriptFunction(
  funcName: string,
  typeArgs: string[],
  args: mv.MoveType[],
  sender?: UserContext,
  moduleAddress?: string,
) {
  sender = sender || defaultUserContext;
  moduleAddress = moduleAddress || defaultUserContext.address;

  return await DiemHelpers.invokeScriptFunctionForContext(
    sender,
    `${moduleAddress}::${funcName}`,
    typeArgs,
    args,
  );
}
