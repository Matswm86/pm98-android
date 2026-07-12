// FUN_004c5ae0  entry=004c5ae0  size=581 bytes

void __fastcall FUN_004c5ae0(int param_1)

{
  uint uVar1;
  int iVar2;
  int iVar3;
  int iVar4;
  ushort *puVar5;
  bool bVar6;
  int local_c;
  int local_8;
  undefined4 local_4;
  
  local_8 = 0;
  if (0 < *(int *)(param_1 + 0xcf94)) {
    local_c = 0;
    do {
      bVar6 = false;
      puVar5 = (ushort *)(param_1 + 0x61e8);
      iVar4 = 5;
      do {
        iVar2 = local_c + *(int *)(param_1 + 0xcf8c);
        if ((uint)*puVar5 == *(uint *)(iVar2 + 0x54)) {
          if ((~(byte)(*(uint *)(iVar2 + 0xac) >> 7) & 1) != 0) {
            FUN_005bf8c0(0,1);
          }
          bVar6 = true;
        }
        puVar5 = puVar5 + 0x41c;
        iVar4 = iVar4 + -1;
      } while (iVar4 != 0);
      iVar4 = 0;
      if (0 < DAT_0066c17c) {
        iVar2 = 0;
        do {
          iVar3 = *(int *)(param_1 + 0xcf8c) + local_c;
          if (*(int *)(iVar2 + 0x24 + DAT_0066c178) == *(int *)(iVar3 + 0x54)) {
            if ((~(byte)(*(uint *)(iVar3 + 0xac) >> 7) & 1) != 0) {
              FUN_005bf8c0(0,1);
            }
            bVar6 = true;
          }
          iVar4 = iVar4 + 1;
          iVar2 = iVar2 + 0x9c;
        } while (iVar4 < DAT_0066c17c);
      }
      if ((*(int *)(param_1 + 0xcf98) < 5) && (iVar4 = 0, 0 < *(int *)(param_1 + 0x2164))) {
        do {
          if (*(uint *)(*(int *)(param_1 + 0xcf8c) + 0x54 + local_c) ==
              (uint)*(ushort *)(*(int *)(param_1 + 0x215c) + iVar4 * 2)) {
            local_4 = *(undefined4 *)(param_1 + 0x61ec + *(int *)(param_1 + 0xcf98) * 0x838);
            iVar2 = FUN_004ecf70(&local_4);
            if (iVar2 != 0) {
              if ((~(byte)(*(uint *)(*(int *)(param_1 + 0xcf8c) + local_c + 0xac) >> 7) & 1) != 0) {
                FUN_005bf8c0(0,1);
              }
              bVar6 = true;
            }
          }
          iVar4 = iVar4 + 1;
        } while (iVar4 < *(int *)(param_1 + 0x2164));
      }
      if (((!bVar6) &&
          (iVar4 = *(int *)(param_1 + 0xcf8c) + local_c,
          (~(byte)(*(uint *)(iVar4 + 0xac) >> 7) & 1) == 0)) &&
         ((*(uint *)(iVar4 + 0xac) >> 7 & 1) != 0)) {
        FUN_005bf8c0(1,1);
      }
      local_8 = local_8 + 1;
      local_c = local_c + 0x428;
    } while (local_8 < *(int *)(param_1 + 0xcf94));
  }
  bVar6 = *(int *)(param_1 + 0xcf98) == 4;
  local_4 = CONCAT31(local_4._1_3_,bVar6);
  if (bVar6) {
    uVar1 = *(uint *)(param_1 + 0xd460) >> 7;
  }
  else {
    uVar1 = (uint)(byte)~(byte)(*(uint *)(param_1 + 0xd460) >> 7);
  }
  if ((uVar1 & 1) != 0) {
    FUN_005bf8c0(local_4,1);
  }
  bVar6 = 0 < *(int *)(param_1 + 0xcf98);
  local_4 = CONCAT31(local_4._1_3_,bVar6);
  if (bVar6) {
    uVar1 = *(uint *)(param_1 + 0xd048) >> 7;
  }
  else {
    uVar1 = (uint)(byte)~(byte)(*(uint *)(param_1 + 0xd048) >> 7);
  }
  if ((uVar1 & 1) != 0) {
    FUN_005bf8c0(local_4,1);
  }
  return;
}


