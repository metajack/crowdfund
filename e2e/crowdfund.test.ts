// Copyright (c) The Diem Core Contributors
// SPDX-License-Identifier: Apache-2.0
//
// This file is generated on new project creation.

import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.85.0/testing/asserts.ts";
import * as devapi from "../main/devapi.ts";
import * as main from "../main/mod.ts";
import * as context from "../main/context.ts";

Deno.test("Sensible end time", async () => {
  let current_secs = await main.current_secs();
  let txn = await main.creator_createProject(100000000000, current_secs - 24*60*60);
  txn = await devapi.waitForTransaction(txn.hash);
  assert(!txn.success);
});
