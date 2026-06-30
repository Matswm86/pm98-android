// FUN_0045b890  entry=0045b890  size=793 bytes

/* WARNING: Restarted to delay deadcode elimination for space: stack */

char __thiscall
FUN_0045b890(void *this,int *param_1,int *param_2,int *param_3,int *param_4,int *param_5)

{
  int iVar1;
  int iVar2;
  undefined4 uVar3;
  byte *pbVar4;
  byte *pbVar5;
  bool bVar6;
  byte bVar7;
  ushort uVar8;
  byte bVar15;
  undefined4 uVar9;
  uint uVar10;
  uint uVar11;
  byte bVar14;
  uint uVar12;
  int iVar13;
  uint uVar16;
  uint uVar17;
  char cVar18;
  int iVar19;
  char *pcVar20;
  byte *pbVar21;
  byte *pbVar22;
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
  
  local_44 = *param_1;
  local_40 = param_1[1];
  local_3c = param_1[2];
  local_38 = param_1[3];
  local_2c = *param_5;
  local_28 = param_5[1];
  local_34 = *param_3 + param_2[0xe];
  local_30 = param_3[1] + param_2[0xf];
  FUN_004063b0(&local_34,param_2 + 10);
  local_2c = local_2c + param_4[0xe];
  local_28 = local_28 + param_4[0xf];
  FUN_004063b0(&local_2c,param_4 + 10);
  local_40 = local_40 + *(int *)((int)this + 0x3c);
  local_44 = local_44 + *(int *)((int)this + 0x38);
  local_3c = local_3c + *(int *)((int)this + 0x38);
  local_38 = local_38 + *(int *)((int)this + 0x3c);
  local_24 = local_44;
  local_20 = local_40;
  FUN_0044f980(&local_44,(int *)((int)this + 0x28));
  FUN_0044f940(&local_24,&local_44);
  FUN_0044f940(&local_34,&local_24);
  FUN_0044f940(&local_2c,&local_24);
  uVar9 = FUN_0044f960(&local_44);
  cVar18 = '\x01' - ((char)uVar9 != '\0');
  if (cVar18 == '\0') {
    if ((*(int *)this != 0) || (bVar6 = FUN_0044e840(this), bVar6)) {
      bVar6 = true;
    }
    else {
      bVar6 = false;
    }
    if (bVar6) {
      if ((*param_2 != 0) || (bVar6 = FUN_0044e840(param_2), bVar6)) {
        bVar6 = true;
      }
      else {
        bVar6 = false;
      }
      if (bVar6) {
        if ((*param_4 != 0) || (bVar6 = FUN_0044e840(param_4), bVar6)) {
          bVar6 = true;
        }
        else {
          bVar6 = false;
        }
        if (bVar6) {
          local_5c = local_38 - local_40;
          uVar10 = local_3c - local_44;
          iVar19 = *(int *)((int)this + 0x1c) - uVar10;
          iVar1 = param_2[7];
          iVar2 = param_4[7];
          pcVar20 = (char *)(local_30 * param_2[7] + local_34 + *param_2);
          uVar16 = (-(local_44 + local_40) & 1U) << 0x10;
          uVar11 = (~uVar10 & 1) << 0x10;
          uVar17 = uVar10;
          pbVar4 = (byte *)(local_28 * param_4[7] + local_2c + *param_4);
          pbVar5 = (byte *)(local_40 * *(int *)((int)this + 0x1c) + local_44 + *(int *)this);
          do {
            do {
              while( true ) {
                pbVar22 = pbVar5;
                pbVar21 = pbVar4;
                uVar16 = uVar16 ^ 0x10000;
                cVar18 = *pcVar20;
                pcVar20 = pcVar20 + 1;
                if (cVar18 != '\0') break;
joined_r0x0045baf1:
                uVar17 = uVar17 - 1;
                pbVar4 = pbVar21 + 1;
                pbVar5 = pbVar22 + 1;
                if (uVar17 == 0) {
                  local_5c = local_5c + -1;
                  uVar16 = uVar16 ^ uVar11;
                  pcVar20 = pcVar20 + (iVar1 - uVar10);
                  uVar17 = uVar10;
                  pbVar4 = pbVar21 + 1 + (iVar2 - uVar10);
                  pbVar5 = pbVar22 + 1 + iVar19;
                  if (local_5c == 0) goto LAB_0045bb97;
                }
              }
              bVar7 = cVar18 + 1;
              if (bVar7 == 0) {
                *pbVar22 = *pbVar21;
                goto joined_r0x0045baf1;
              }
              uVar8 = (ushort)bVar7;
              uVar9 = (&DAT_004f612c)[*pbVar21];
              uVar3 = (&DAT_004f612c)[*pbVar22];
              bVar14 = (byte)uVar3;
              bVar14 = (char)((ushort)(CONCAT11(-((byte)uVar9 < bVar14),(byte)uVar9 - bVar14) *
                                      uVar8) >> 8) + bVar14;
              uVar12 = CONCAT31(CONCAT21((short)((uint)uVar9 >> 0x10),bVar14),
                                (char)((uint)uVar9 >> 8)) & 0xfffff8ff;
              bVar7 = (byte)uVar12;
              bVar15 = (byte)((uint)uVar3 >> 8);
              iVar13 = ((byte)((char)((ushort)(CONCAT11(-(bVar7 < bVar15),bVar7 - bVar15) * uVar8)
                                     >> 8) + bVar15) & 0x1fffe0fc) << 3;
              bVar7 = (byte)((uint)uVar3 >> 0x10);
              bVar15 = (byte)(uVar12 >> 0x10);
              uVar16 = CONCAT31(CONCAT21((short)(uVar16 >> 0x10),
                                         bVar14 & 0xf8 | (byte)((uint)iVar13 >> 8)),
                                (byte)iVar13 |
                                (byte)((char)((ushort)(CONCAT11(-(bVar15 < bVar7),bVar15 - bVar7) *
                                                      uVar8) >> 8) + bVar7) >> 3);
              *pbVar22 = *(byte *)((int)&DAT_004b3a88 + uVar16);
              uVar17 = (uVar17 & 0xff | (uint)((ushort)(uVar17 >> 8) & 0xff) << 8) - 1;
              pbVar4 = pbVar21 + 1;
              pbVar5 = pbVar22 + 1;
            } while (uVar17 != 0);
            pcVar20 = pcVar20 + (iVar1 - uVar10);
            uVar16 = uVar16 ^ uVar11;
            local_5c = local_5c + -1;
            uVar17 = uVar10;
            pbVar4 = pbVar21 + 1 + (iVar2 - uVar10);
            pbVar5 = pbVar22 + 1 + iVar19;
          } while (local_5c != 0);
LAB_0045bb97:
          param_4._3_1_ = '\x01';
          cVar18 = param_4._3_1_;
        }
      }
    }
  }
  return cVar18;
}


