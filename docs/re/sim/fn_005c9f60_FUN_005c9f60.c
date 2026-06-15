// FUN_005c9f60  entry=005c9f60  size=439 bytes
// callers/callees expanded one level from seeds

uint FUN_005c9f60(undefined4 param_1,undefined4 param_2,undefined4 param_3)

{
  int iVar1;
  LPSTR pCVar2;
  uint uVar3;
  CHAR local_110 [16];
  undefined1 local_100 [256];
  
  iVar1 = FUN_005ec1d0(param_1);
  if (iVar1 == 0) {
    uVar3 = FUN_005c9a30(1,1,8,0,0xffffffff);
    return uVar3 & 0xffffff00;
  }
  pCVar2 = (LPSTR)FUN_005e5c50(local_100,0xfffffffc);
  pCVar2 = CharUpperA(pCVar2);
  lstrcpyA(local_110,pCVar2);
  iVar1 = lstrcmpA(local_110,&DAT_0066578c);
  if (iVar1 == 0) {
    uVar3 = FUN_005ca120(param_1,param_2,param_3);
    return uVar3;
  }
  iVar1 = lstrcmpA(local_110,&DAT_00665bbc);
  if (iVar1 == 0) {
    uVar3 = FUN_005ca4f0(param_1,param_2,param_3);
    return uVar3;
  }
  iVar1 = lstrcmpA(local_110,&DAT_00665958);
  if (iVar1 == 0) {
    uVar3 = FUN_005ca730(param_1,param_2,param_3);
    return uVar3;
  }
  iVar1 = lstrcmpA(local_110,&DAT_00665bb4);
  if (iVar1 == 0) {
    uVar3 = FUN_005caa20(param_1,param_2,param_3);
    return uVar3;
  }
  iVar1 = lstrcmpA(local_110,&DAT_0066593c);
  if (iVar1 != 0) {
    iVar1 = lstrcmpA(local_110,&DAT_00665944);
    if (iVar1 != 0) {
      return 0;
    }
  }
  uVar3 = FUN_005cacd0(param_1,param_2,param_3);
  return uVar3;
}


