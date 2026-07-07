// FUN_005aad30  entry=005aad30  size=258 bytes
// callers/callees expanded one level from seeds

void __fastcall FUN_005aad30(int param_1)

{
  int iVar1;
  int iVar2;
  int iVar3;
  int iVar4;
  int iVar5;
  undefined2 extraout_var;
  undefined4 local_18;
  undefined4 local_14;
  undefined4 local_10;
  undefined4 local_c;
  undefined4 local_8;
  
  *(undefined4 *)(param_1 + 0x48) = 0;
  FUN_005ee0f0(0x40000,*(undefined2 *)(param_1 + 0x34));
  FUN_005ee0f0(0x39999,CONCAT22(extraout_var,*(undefined2 *)(param_1 + 0x34)));
  iVar1 = *(int *)(param_1 + 4);
  iVar2 = *(int *)(param_1 + 8);
  iVar3 = *(int *)(param_1 + 0xc);
  iVar4 = *(int *)(*(int *)(param_1 + 400) + 4);
  iVar5 = *(int *)(*(int *)(param_1 + 400) + 8);
  FUN_005a5430(0x36);
  *(undefined4 *)(param_1 + 0x84) = 0x80;
  *(int *)(param_1 + 0x94) = local_18 + iVar1;
  *(undefined4 *)(param_1 + 0x80) = 1;
  *(int *)(param_1 + 0x98) = local_14 + iVar2;
  *(int *)(param_1 + 0x9c) = local_10 + iVar3;
  iVar1 = *(int *)(param_1 + 400);
  *(undefined2 *)(param_1 + 0x66) = *(undefined2 *)(param_1 + 0x34);
  *(undefined4 *)(iVar1 + 0x68) = 1;
  *(undefined4 *)(iVar1 + 0x6c) = 0x58;
  *(int *)(iVar1 + 0x9c) = local_c + iVar4;
  *(int *)(iVar1 + 0xa0) = local_8 + iVar5;
  *(undefined4 *)(iVar1 + 0xa4) = 0xb333;
  *(undefined4 *)(*(int *)(param_1 + 0x18c) + 0x19dc) = 10000;
  return;
}


