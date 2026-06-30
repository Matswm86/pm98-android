// FUN_0045bbb0  entry=0045bbb0  size=519 bytes

char __thiscall FUN_0045bbb0(void *this,int *param_1,ushort param_2,int *param_3,int *param_4)

{
  int iVar1;
  int iVar2;
  undefined4 uVar3;
  bool bVar4;
  byte bVar5;
  byte bVar10;
  undefined4 uVar6;
  uint uVar7;
  uint uVar8;
  int iVar9;
  ushort uVar11;
  short sVar12;
  uint uVar13;
  uint uVar14;
  char cVar15;
  byte bVar17;
  byte *pbVar16;
  byte *pbVar18;
  int local_40;
  int local_3c;
  int local_38;
  int local_34;
  int local_30;
  int local_2c;
  int local_28;
  int local_24;
  undefined2 local_18;
  
  local_30 = *param_4 + param_3[0xe];
  local_2c = param_4[1] + param_3[0xf];
  local_3c = param_1[1] + *(int *)((int)this + 0x3c);
  local_38 = param_1[2] + *(int *)((int)this + 0x38);
  local_40 = *param_1 + *(int *)((int)this + 0x38);
  local_34 = param_1[3] + *(int *)((int)this + 0x3c);
  local_28 = local_40;
  local_24 = local_3c;
  FUN_0044f980(&local_40,(int *)((int)this + 0x28));
  local_28 = local_28 - local_40;
  local_24 = local_24 - local_3c;
  FUN_0044f940(&local_30,&local_28);
  uVar6 = FUN_0044f960(&local_40);
  cVar15 = '\x01' - ((char)uVar6 != '\0');
  if (cVar15 != '\0') {
    return cVar15;
  }
  if ((*(int *)this != 0) || (bVar4 = FUN_0044e840(this), bVar4)) {
    bVar4 = true;
  }
  else {
    bVar4 = false;
  }
  if (bVar4) {
    if ((*param_3 != 0) || (bVar4 = FUN_0044e840(param_3), bVar4)) {
      bVar4 = true;
    }
    else {
      bVar4 = false;
    }
    param_1._3_1_ = '\0';
    if (bVar4) {
      param_4 = (int *)(local_34 - local_3c);
      uVar7 = local_38 - local_40;
      iVar1 = *(int *)((int)this + 0x1c);
      iVar2 = param_3[7];
      pbVar16 = (byte *)(local_3c * iVar1 + local_40 + *(int *)this);
      pbVar18 = (byte *)(local_2c * param_3[7] + local_30 + *param_3);
      uVar14 = (-(local_40 + local_3c) & 1U) << 0x10;
      uVar13 = (param_2 & 0xff00) << 8 | (uint)param_2 << 0x18;
      do {
        local_18 = (undefined2)uVar7;
        uVar13 = CONCAT22((short)(uVar13 >> 0x10),local_18);
        do {
          uVar11 = (ushort)(byte)(uVar13 >> 0x18) | (ushort)((uVar13 & 0xff0000) >> 8);
          bVar5 = *pbVar18;
          pbVar18 = pbVar18 + 1;
          uVar6 = (&DAT_004f612c)[bVar5];
          uVar3 = (&DAT_004f612c)[*pbVar16];
          bVar10 = (byte)uVar3;
          bVar10 = (char)((ushort)(CONCAT11(-((byte)uVar6 < bVar10),(byte)uVar6 - bVar10) * uVar11)
                         >> 8) + bVar10;
          uVar8 = CONCAT31(CONCAT21((short)((uint)uVar6 >> 0x10),bVar10),(char)((uint)uVar6 >> 8)) &
                  0xfffff8ff;
          bVar5 = (byte)uVar8;
          bVar17 = (byte)((uint)uVar3 >> 8);
          iVar9 = ((byte)((char)((ushort)(CONCAT11(-(bVar5 < bVar17),bVar5 - bVar17) * uVar11) >> 8)
                         + bVar17) & 0x1fffe0fc) << 3;
          bVar17 = (byte)(uVar8 >> 0x10);
          bVar5 = (byte)((uint)uVar3 >> 0x10);
          uVar14 = CONCAT31(CONCAT21((short)(uVar14 >> 0x10),
                                     bVar10 & 0xf8 | (byte)((uint)iVar9 >> 8)),
                            (byte)iVar9 |
                            (byte)((char)((ushort)(CONCAT11(-(bVar17 < bVar5),bVar17 - bVar5) *
                                                  uVar11) >> 8) + bVar5) >> 3) ^ 0x10000;
          *pbVar16 = *(byte *)((int)&DAT_004b3a88 + uVar14);
          pbVar16 = pbVar16 + 1;
          sVar12 = (short)uVar13 + -1;
          uVar13 = CONCAT22((ushort)((uVar13 & 0xff0000) >> 0x10) |
                            (ushort)(uVar13 >> 0x10) & 0xff00,sVar12);
        } while (sVar12 != 0);
        uVar14 = uVar14 ^ (~uVar7 & 1) << 0x10;
        pbVar16 = pbVar16 + (iVar1 - uVar7);
        pbVar18 = pbVar18 + (iVar2 - uVar7);
        param_4 = (int *)((int)param_4 + -1);
      } while (param_4 != (int *)0x0);
      param_1._3_1_ = '\x01';
    }
    return param_1._3_1_;
  }
  return '\0';
}


