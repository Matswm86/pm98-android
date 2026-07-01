// FUN_005eeba0  entry=005eeba0  size=190 bytes

undefined4 * __thiscall
FUN_005eeba0(undefined4 *param_1,int *param_2,int param_3,int param_4,int param_5)

{
  undefined4 uVar1;
  undefined4 *puVar2;
  int iVar3;
  undefined4 *puVar4;
  int local_6c;
  int local_68;
  int local_64;
  undefined1 local_30 [48];
  
  local_6c = -*param_2;
  local_68 = -param_2[1];
  local_64 = -param_2[2];
  FUN_005eea10(&local_6c);
  uVar1 = FUN_005eea80(-param_3);
  puVar2 = (undefined4 *)FUN_005ee800(local_30,uVar1);
  puVar4 = param_1;
  for (iVar3 = 0xc; iVar3 != 0; iVar3 = iVar3 + -1) {
    *puVar4 = *puVar2;
    puVar2 = puVar2 + 1;
    puVar4 = puVar4 + 1;
  }
  uVar1 = FUN_005eeae0(-param_4);
  puVar2 = (undefined4 *)FUN_005ee800(local_30,uVar1);
  puVar4 = param_1;
  for (iVar3 = 0xc; iVar3 != 0; iVar3 = iVar3 + -1) {
    *puVar4 = *puVar2;
    puVar2 = puVar2 + 1;
    puVar4 = puVar4 + 1;
  }
  uVar1 = FUN_005eeb40(-param_5);
  puVar2 = (undefined4 *)FUN_005ee800(local_30,uVar1);
  puVar4 = param_1;
  for (iVar3 = 0xc; iVar3 != 0; iVar3 = iVar3 + -1) {
    *puVar4 = *puVar2;
    puVar2 = puVar2 + 1;
    puVar4 = puVar4 + 1;
  }
  return param_1;
}


