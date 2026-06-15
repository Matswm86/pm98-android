// FUN_0043ca50  entry=0043ca50  size=417 bytes

undefined4 FUN_0043ca50(int *param_1,int param_2,undefined4 param_3)

{
  int *piVar1;
  int iVar2;
  char cVar3;
  undefined4 uVar4;
  undefined4 uVar5;
  undefined4 *puVar6;
  int iVar7;
  int iVar8;
  int iVar9;
  int iVar10;
  undefined4 uVar11;
  int local_20;
  int local_1c;
  undefined1 local_18 [24];
  
  uVar4 = FUN_005db6b0(param_3,&DAT_006c29b4,0x100,0xffffffff);
  piVar1 = param_1 + 2;
  local_20 = param_1[2] - *param_1;
  local_1c = param_2;
  uVar11 = uVar4;
  uVar5 = FUN_00435e60(local_18,&local_20);
  puVar6 = (undefined4 *)FUN_0043cc00(param_1,uVar5);
  cVar3 = FUN_005cb930(*puVar6,puVar6[1],puVar6[2],puVar6[3],uVar11);
  if (cVar3 != '\0') {
    FUN_00436fb0(param_2 + *param_1,param_1[3]);
    uVar11 = uVar4;
    puVar6 = (undefined4 *)FUN_0043cc00(param_1,&local_20);
    cVar3 = FUN_005cb930(*puVar6,puVar6[1],puVar6[2],puVar6[3],uVar11);
    if (cVar3 != '\0') {
      FUN_00436fb0((*param_1 + *piVar1) - *piVar1,param_1[3] + -param_2);
      uVar11 = uVar4;
      puVar6 = (undefined4 *)FUN_0043cc00(piVar1,&local_20);
      cVar3 = FUN_005cb930(*puVar6,puVar6[1],puVar6[2],puVar6[3],uVar11);
      if (cVar3 != '\0') {
        iVar8 = *piVar1;
        iVar2 = param_1[3];
        iVar10 = iVar8 + -param_2;
        iVar7 = (iVar2 - param_1[3]) + param_1[1];
        iVar9 = iVar8;
        if (iVar10 <= iVar8) {
          iVar9 = iVar10;
        }
        if (iVar8 <= iVar10) {
          iVar8 = iVar10;
        }
        iVar10 = iVar2;
        if (iVar7 <= iVar2) {
          iVar10 = iVar7;
        }
        if (iVar7 < iVar2) {
          iVar7 = iVar2;
        }
        cVar3 = FUN_005cb930(iVar9,iVar10,iVar8,iVar7,uVar4);
        if (cVar3 != '\0') {
          return 1;
        }
      }
    }
  }
  return 0;
}


