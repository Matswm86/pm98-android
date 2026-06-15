// FUN_005db6b0  entry=005db6b0  size=376 bytes
// callers/callees expanded one level from seeds

int FUN_005db6b0(uint param_1,int param_2,int param_3,int param_4)

{
  int iVar1;
  uint uVar2;
  uint uVar3;
  int iVar4;
  int iVar5;
  uint uVar6;
  int iVar7;
  int iVar8;
  uint uVar9;
  int iVar10;
  int iVar11;
  int local_10;
  int local_c;
  
  iVar1 = 0;
  if ((param_1 & 0xffffff) != 0) {
    if (param_4 < 0) {
      param_4 = param_3 / 2;
    }
    uVar2 = (uint)*(byte *)(param_2 + param_4 * 4) - (param_1 & 0xff);
    uVar9 = param_1 >> 8 & 0xff;
    uVar6 = (int)uVar2 >> 0x1f;
    uVar3 = *(byte *)(param_2 + 1 + param_4 * 4) - uVar9;
    iVar11 = (uVar2 ^ uVar6) - uVar6;
    uVar2 = (int)uVar3 >> 0x1f;
    iVar8 = (uVar3 ^ uVar2) - uVar2;
    uVar2 = (uint)*(byte *)(param_2 + 2 + param_4 * 4) - (uint)(param_1._2_2_ & 0xff);
    uVar3 = (int)uVar2 >> 0x1f;
    local_10 = (uVar2 ^ uVar3) - uVar3;
    iVar7 = iVar11 * iVar11 + iVar8 * iVar8 + local_10 * local_10;
    iVar1 = param_2 + -4 + param_3 * 4;
    param_2._0_1_ = (undefined1)iVar1;
    param_2._1_1_ = (undefined1)((uint)iVar1 >> 8);
    param_2._2_2_ = (undefined2)((uint)iVar1 >> 0x10);
    local_c = iVar8;
    iVar1 = param_4;
    while (param_3 != 0) {
      param_3 = param_3 + -1;
      uVar2 = (uint)*(byte *)CONCAT22(param_2._2_2_,CONCAT11(param_2._1_1_,(undefined1)param_2)) -
              (param_1 & 0xff);
      uVar3 = (int)uVar2 >> 0x1f;
      iVar5 = (uVar2 ^ uVar3) - uVar3;
      uVar2 = *(byte *)(CONCAT22(param_2._2_2_,CONCAT11(param_2._1_1_,(undefined1)param_2)) + 1) -
              uVar9;
      uVar3 = (int)uVar2 >> 0x1f;
      iVar10 = (uVar2 ^ uVar3) - uVar3;
      uVar2 = (uint)*(byte *)(CONCAT22(param_2._2_2_,CONCAT11(param_2._1_1_,(undefined1)param_2)) +
                             2) - (uint)(param_1._2_2_ & 0xff);
      uVar3 = (int)uVar2 >> 0x1f;
      iVar4 = (uVar2 ^ uVar3) - uVar3;
      param_4 = iVar1;
      if ((((iVar5 < iVar11) || (iVar10 < iVar8)) || (iVar4 < local_10)) &&
         (iVar1 = iVar5 * iVar5 + iVar10 * iVar10 + iVar4 * iVar4, iVar8 = local_c, iVar1 < iVar7))
      {
        param_4 = param_3;
        iVar7 = iVar1;
        iVar8 = iVar10;
        iVar11 = iVar5;
        local_10 = iVar4;
        local_c = iVar10;
      }
      iVar1 = CONCAT22(param_2._2_2_,CONCAT11(param_2._1_1_,(undefined1)param_2)) + -4;
      param_2._0_1_ = (undefined1)iVar1;
      param_2._1_1_ = (undefined1)((uint)iVar1 >> 8);
      param_2._2_2_ = (undefined2)((uint)iVar1 >> 0x10);
      iVar1 = param_4;
    }
  }
  return iVar1;
}


