// FUN_00459930  entry=00459930  size=414 bytes

void __fastcall FUN_00459930(CWnd *param_1)

{
  int iVar1;
  bool bVar2;
  HBRUSH hbr;
  int iVar3;
  tagRECT local_70;
  CPaintDC local_60 [4];
  HDC local_5c;
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_00482c68;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  CPaintDC::CPaintDC(local_60,param_1);
  local_4 = 0;
  if (DAT_004959b4 == '\0') {
    if ((DAT_0050178c < 1) || (*(int *)(DAT_00501788 + 0x18 + DAT_00501d74 * 0x134) == 0)) {
      bVar2 = false;
    }
    else {
      bVar2 = true;
    }
    if (bVar2) {
      if (*(int *)(param_1 + 600) != 0) {
        local_70.top = 0x70000000;
        local_70.left = 0x70000000;
        local_70.bottom = -0x70000000;
        local_70.right = -0x70000000;
        CDC::GetClipBox((CDC *)local_60,&local_70);
        FUN_00456230(param_1,(LPPOINT)&local_70);
        FUN_004562f0(*(void **)(param_1 + 600),(LPPOINT)&local_70);
        iVar1 = *(int *)(param_1 + 600);
        iVar3 = *(int *)(iVar1 + 0x40c);
        if (local_70.left <= iVar3) {
          iVar3 = local_70.left;
        }
        *(int *)(iVar1 + 0x40c) = iVar3;
        iVar3 = *(int *)(iVar1 + 0x410);
        if (local_70.top <= *(int *)(iVar1 + 0x410)) {
          iVar3 = local_70.top;
        }
        *(int *)(iVar1 + 0x410) = iVar3;
        iVar3 = *(int *)(iVar1 + 0x414);
        if (*(int *)(iVar1 + 0x414) <= local_70.right) {
          iVar3 = local_70.right;
        }
        *(int *)(iVar1 + 0x414) = iVar3;
        iVar3 = *(int *)(iVar1 + 0x418);
        if (*(int *)(iVar1 + 0x418) <= local_70.bottom) {
          iVar3 = local_70.bottom;
        }
        *(int *)(iVar1 + 0x418) = iVar3;
        iVar1 = *(int *)(param_1 + 600);
        if ((*(int *)(iVar1 + 0x40c) < *(int *)(iVar1 + 0x414)) &&
           (*(int *)(iVar1 + 0x410) < *(int *)(iVar1 + 0x418))) {
          bVar2 = true;
        }
        else {
          bVar2 = false;
        }
        if (bVar2) {
          *(undefined4 *)(iVar1 + 0x42c) = 1;
        }
      }
      goto LAB_00459aad;
    }
  }
  local_70.left = -0x2000;
  local_70.right = 0x2000;
  local_70.top = -0x2000;
  local_70.bottom = 0x2000;
  hbr = GetStockObject(4);
  FillRect(local_5c,&local_70,hbr);
LAB_00459aad:
  local_4 = 0xffffffff;
  CPaintDC::~CPaintDC(local_60);
  ExceptionList = local_c;
  return;
}


