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

export async function creator_ProjectCreate(
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

export async function decodedMessages(addr?: string) {
  return (await devapi.resourcesWithName("MessageHolder", addr))
    .map((entry) => entry.data.message);
}

export async function messageEvents(
  start?: number,
  limit?: number,
  addr?: string,
  moduleAddress?: string
) {
  moduleAddress = moduleAddress || defaultUserContext.address;
  return await devapi.events(
    `${moduleAddress}::Message::MessageHolder`,
    "message_change_events",
    start,
    limit,
    addr,
  );
}

export async function decodedNFTs(addr?: string) {
  const decodedNfts: any[] = [];
  const nfts = (await devapi.resourcesWithName("NFTStandard", addr))
    .filter((entry) => entry.data && entry.data.nfts)
    .map((entry) => {
      return entry.data.nfts;
    });
  nfts.forEach((nft_type: any) => {
    nft_type.forEach((nft: any) => {
      decodedNfts.push({
        id: nft.id,
        content_uri: DiemHelpers.hexToAscii(nft.content_uri),
      });
    });
  });
  return decodedNfts;
}
