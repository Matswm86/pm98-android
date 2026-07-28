// FUN_005d5540  entry=005d5540  size=521 bytes

undefined4 __thiscall
FUN_005d5540(int *param_1,int *param_2,ushort param_3,int *param_4,int *param_5)

{
  int iVar1;
  int iVar2;
  int iVar3;
  int iVar4;
  int iVar5;
  int iVar6;
  int iVar7;
  undefined4 uVar8;
  undefined4 uVar9;
  bool bVar10;
  char extraout_AL;
  char cVar11;
  byte bVar12;
  byte bVar13;
  byte bVar18;
  int iVar14;
  uint3 extraout_var;
  uint uVar15;
  uint uVar16;
  int iVar17;
  uint3 uVar19;
  ushort uVar20;
  short sVar21;
  int iVar22;
  uint uVar23;
  uint uVar24;
  byte *pbVar25;
  byte *pbVar26;
  int local_28;
  int local_24;
  undefined2 local_18;
  
  iVar1 = param_2[2];
  iVar2 = param_2[3];
  iVar17 = param_5[1];
  iVar3 = *param_5;
  iVar4 = param_4[0xe];
  iVar5 = param_4[0xf];
  iVar6 = param_1[0xe];
  iVar22 = param_2[1] + param_1[0xf];
  iVar14 = *param_2 + iVar6;
  iVar7 = param_1[0xf];
  local_28 = iVar14;
  local_24 = iVar22;
  FUN_005c3410(param_1 + 10);
  local_28 = local_28 - iVar14;
  local_24 = local_24 - iVar22;
  FUN_005d4220(&local_28);
  FUN_005d4240();
  param_2._3_1_ = '\x01' - (extraout_AL != '\0');
  uVar19 = extraout_var;
  if (param_2._3_1_ != '\0') goto LAB_005d573e;
  if (*param_1 == 0) {
    cVar11 = FUN_005cb2b0();
    if (cVar11 != '\0') goto LAB_005d5600;
    bVar10 = false;
  }
  else {
LAB_005d5600:
    bVar10 = true;
  }
  uVar19 = 0;
  if (!bVar10) goto LAB_005d573e;
  if (*param_4 == 0) {
    cVar11 = FUN_005cb2b0();
    if (cVar11 != '\0') goto LAB_005d5621;
    bVar10 = false;
  }
  else {
LAB_005d5621:
    bVar10 = true;
  }
  uVar19 = 0;
  if (bVar10) {
    param_5 = (int *)((iVar2 + iVar7) - iVar22);
    uVar15 = (iVar1 + iVar6) - iVar14;
    iVar1 = param_1[7];
    iVar2 = param_4[7];
    pbVar25 = (byte *)(iVar22 * iVar1 + *param_1 + iVar14);
    pbVar26 = (byte *)((iVar17 + iVar5) * param_4[7] + *param_4 + iVar3 + iVar4);
    uVar24 = (-(iVar14 + iVar22) & 1U) << 0x10;
    uVar23 = (param_3 & 0xff00) << 8 | (uint)param_3 << 0x18;
    do {
      local_18 = (undefined2)uVar15;
      uVar23 = CONCAT22((short)(uVar23 >> 0x10),local_18);
      do {
        uVar20 = (ushort)(byte)(uVar23 >> 0x18) | (ushort)((uVar23 & 0xff0000) >> 8);
        bVar12 = *pbVar26;
        pbVar26 = pbVar26 + 1;
        uVar8 = (&DAT_006c29b4)[bVar12];
        uVar9 = (&DAT_006c29b4)[*pbVar25];
        bVar18 = (byte)uVar9;
        bVar18 = (char)((ushort)(CONCAT11(-((byte)uVar8 < bVar18),(byte)uVar8 - bVar18) * uVar20) >>
                       8) + bVar18;
        uVar16 = CONCAT31(CONCAT21((short)((uint)uVar8 >> 0x10),bVar18),(char)((uint)uVar8 >> 8)) &
                 0xfffff8ff;
        bVar12 = (byte)uVar16;
        bVar13 = (byte)((uint)uVar9 >> 8);
        iVar17 = ((byte)((char)((ushort)(CONCAT11(-(bVar12 < bVar13),bVar12 - bVar13) * uVar20) >> 8
                               ) + bVar13) & 0x1fffe0fc) << 3;
        bVar12 = (byte)((uint)uVar9 >> 0x10);
        bVar13 = (byte)(uVar16 >> 0x10);
        uVar19 = (uint3)(ushort)((ushort)iVar17 >> 3);
        uVar24 = CONCAT31(CONCAT21((short)(uVar24 >> 0x10),bVar18 & 0xf8 | (byte)((uint)iVar17 >> 8)
                                  ),
                          (byte)iVar17 |
                          (byte)(CONCAT21((ushort)iVar17,
                                          (char)((ushort)(CONCAT11(-(bVar13 < bVar12),
                                                                   bVar13 - bVar12) * uVar20) >> 8)
                                          + bVar12) >> 3)) ^ 0x10000;
        *pbVar25 = *(byte *)((int)&DAT_00675398 + uVar24);
        pbVar25 = pbVar25 + 1;
        sVar21 = (short)uVar23 + -1;
        uVar23 = CONCAT22((ushort)((uVar23 & 0xff0000) >> 0x10) | (ushort)(uVar23 >> 0x10) & 0xff00,
                          sVar21);
      } while (sVar21 != 0);
      uVar24 = uVar24 ^ (~uVar15 & 1) << 0x10;
      pbVar25 = pbVar25 + (iVar1 - uVar15);
      pbVar26 = pbVar26 + (iVar2 - uVar15);
      param_5 = (int *)((int)param_5 + -1);
    } while (param_5 != (int *)0x0);
    param_2._3_1_ = '\x01';
  }
LAB_005d573e:
  return CONCAT31(uVar19,param_2._3_1_);
}


