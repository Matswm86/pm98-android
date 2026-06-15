// FUN_005d5220  entry=005d5220  size=795 bytes
// callers/callees expanded one level from seeds

/* WARNING: Restarted to delay deadcode elimination for space: stack */

undefined4 __thiscall
FUN_005d5220(int *param_1,int *param_2,int *param_3,int *param_4,int *param_5,int *param_6)

{
  int iVar1;
  int iVar2;
  undefined4 uVar3;
  undefined4 uVar4;
  bool bVar5;
  byte *pbVar6;
  byte *pbVar7;
  char extraout_AL;
  char cVar8;
  byte bVar9;
  ushort uVar10;
  byte bVar16;
  undefined3 extraout_var;
  uint uVar11;
  uint uVar12;
  byte bVar15;
  uint uVar13;
  int iVar14;
  undefined3 uVar17;
  uint uVar18;
  uint uVar19;
  char cVar20;
  int iVar21;
  char *pcVar22;
  byte *pbVar23;
  byte *pbVar24;
  int local_5c;
  int local_44;
  int local_40;
  int local_3c;
  int local_38;
  int local_34;
  int local_30;
  int local_2c;
  int local_28;
  int local_24;
  int local_20;
  
  local_44 = *param_2;
  local_40 = param_2[1];
  local_3c = param_2[2];
  local_38 = param_2[3];
  local_2c = *param_6;
  local_28 = param_6[1];
  local_34 = *param_4 + param_3[0xe];
  local_30 = param_4[1] + param_3[0xf];
  FUN_005d41f0(param_3 + 10);
  local_2c = local_2c + param_5[0xe];
  local_28 = local_28 + param_5[0xf];
  FUN_005d41f0(param_5 + 10);
  local_40 = local_40 + param_1[0xf];
  local_44 = local_44 + param_1[0xe];
  local_3c = local_3c + param_1[0xe];
  local_38 = local_38 + param_1[0xf];
  local_24 = local_44;
  local_20 = local_40;
  FUN_005c3410(param_1 + 10);
  FUN_005d4220(&local_44);
  FUN_005d4220(&local_24);
  FUN_005d4220(&local_24);
  FUN_005d4240();
  cVar20 = '\x01' - (extraout_AL != '\0');
  uVar17 = extraout_var;
  if (cVar20 == '\0') {
    if ((*param_1 == 0) && (cVar8 = FUN_005cb2b0(), cVar8 == '\0')) {
      bVar5 = false;
    }
    else {
      bVar5 = true;
    }
    uVar17 = 0;
    if (bVar5) {
      if ((*param_3 == 0) && (cVar8 = FUN_005cb2b0(), cVar8 == '\0')) {
        bVar5 = false;
      }
      else {
        bVar5 = true;
      }
      uVar17 = 0;
      if (bVar5) {
        if ((*param_5 == 0) && (cVar8 = FUN_005cb2b0(), cVar8 == '\0')) {
          bVar5 = false;
        }
        else {
          bVar5 = true;
        }
        uVar17 = 0;
        if (bVar5) {
          local_5c = local_38 - local_40;
          uVar11 = local_3c - local_44;
          iVar21 = param_1[7] - uVar11;
          iVar1 = param_3[7];
          iVar2 = param_5[7];
          pcVar22 = (char *)(local_30 * param_3[7] + *param_3 + local_34);
          uVar18 = (-(local_44 + local_40) & 1U) << 0x10;
          uVar12 = (~uVar11 & 1) << 0x10;
          uVar19 = uVar11;
          pbVar6 = (byte *)(local_28 * param_5[7] + *param_5 + local_2c);
          pbVar7 = (byte *)(local_40 * param_1[7] + *param_1 + local_44);
          do {
            do {
              while( true ) {
                pbVar24 = pbVar7;
                pbVar23 = pbVar6;
                uVar18 = uVar18 ^ 0x10000;
                cVar20 = *pcVar22;
                pcVar22 = pcVar22 + 1;
                if (cVar20 != '\0') break;
joined_r0x005d5483:
                uVar19 = uVar19 - 1;
                pbVar6 = pbVar23 + 1;
                pbVar7 = pbVar24 + 1;
                if (uVar19 == 0) {
                  local_5c = local_5c + -1;
                  uVar18 = uVar18 ^ uVar12;
                  pcVar22 = pcVar22 + (iVar1 - uVar11);
                  uVar19 = uVar11;
                  pbVar6 = pbVar23 + 1 + (iVar2 - uVar11);
                  pbVar7 = pbVar24 + 1 + iVar21;
                  if (local_5c == 0) goto LAB_005d5529;
                }
              }
              bVar9 = cVar20 + 1;
              if (bVar9 == 0) {
                *pbVar24 = *pbVar23;
                goto joined_r0x005d5483;
              }
              uVar10 = (ushort)bVar9;
              uVar3 = (&DAT_006c29b4)[*pbVar23];
              uVar4 = (&DAT_006c29b4)[*pbVar24];
              bVar15 = (byte)uVar4;
              bVar15 = (char)((ushort)(CONCAT11(-((byte)uVar3 < bVar15),(byte)uVar3 - bVar15) *
                                      uVar10) >> 8) + bVar15;
              uVar13 = CONCAT31(CONCAT21((short)((uint)uVar3 >> 0x10),bVar15),
                                (char)((uint)uVar3 >> 8)) & 0xfffff8ff;
              bVar9 = (byte)uVar13;
              bVar16 = (byte)((uint)uVar4 >> 8);
              iVar14 = ((byte)((char)((ushort)(CONCAT11(-(bVar9 < bVar16),bVar9 - bVar16) * uVar10)
                                     >> 8) + bVar16) & 0x1fffe0fc) << 3;
              bVar9 = (byte)((uint)uVar4 >> 0x10);
              bVar16 = (byte)(uVar13 >> 0x10);
              uVar18 = CONCAT31(CONCAT21((short)(uVar18 >> 0x10),
                                         bVar15 & 0xf8 | (byte)((uint)iVar14 >> 8)),
                                (byte)iVar14 |
                                (byte)((char)((ushort)(CONCAT11(-(bVar16 < bVar9),bVar16 - bVar9) *
                                                      uVar10) >> 8) + bVar9) >> 3);
              *pbVar24 = *(byte *)((int)&DAT_00675398 + uVar18);
              uVar19 = (uVar19 & 0xff | (uint)((ushort)(uVar19 >> 8) & 0xff) << 8) - 1;
              pbVar6 = pbVar23 + 1;
              pbVar7 = pbVar24 + 1;
            } while (uVar19 != 0);
            pcVar22 = pcVar22 + (iVar1 - uVar11);
            uVar18 = uVar18 ^ uVar12;
            local_5c = local_5c + -1;
            uVar19 = uVar11;
            pbVar6 = pbVar23 + 1 + (iVar2 - uVar11);
            pbVar7 = pbVar24 + 1 + iVar21;
          } while (local_5c != 0);
LAB_005d5529:
          uVar17 = 0;
          param_5._3_1_ = '\x01';
          cVar20 = param_5._3_1_;
        }
      }
    }
  }
  return CONCAT31(uVar17,cVar20);
}


