#!/usr/bin/env python3
"""Extract the client's supplied screenshot icons; do not redraw or upscale.

Requires Pillow. Run from any directory: python3 tool/extract_supplemental_icons.py
Source screenshots are retained byte-for-byte in supplemental/source_sheets.
White foreground alpha is recovered against each crop's uniform dark background.
Every output retains the screenshot's pixel grid and has transparent margins.
"""
from pathlib import Path
import json
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / 'assets/icons/supplemental'
# Category: x centers, first y center, row pitch, native icon-slot size, columns.
SHEETS = {
 'arrows': ([86.5,440.5,795],73.5,63.565,24,[
  'Caret_Down_MD Caret_Up_MD Chevron_Left_MD Chevron_Right_MD Chevron_Down Chevron_Up Chevron_Left Chevron_Right Caret_Down_SM Caret_Up_SM Caret_Left_SM Caret_Right_SM Arrow_Down_LG Arrow_Up_LG Arrow_Left_LG Arrow_Right_LG Arrow_Down_Left_LG Arrow_Up_Left_LG Arrow_Up_Right_LG Arrow_Down_Right_LG Arrows_Reload_01 Arrow_Reload_02 Arrow_Left_Right Arrow_Down_Up',
  'Caret_Circle_Down Caret_Circle_Up Caret_Circle_Left Caret_Circle_Right Arrow_Circle_Down Arrow_Circle_Up Arrow_Circle_Left Arrow_Circle_Right Arrow_Circle_Down_Left Arrow_Circle_Up_Left Arrow_Circle_Down_Right Arrow_Circle_Up_Right Arrow_Down_MD Arrow_Up_MD Arrow_Left_MD Arrow_Right_MD Arrow_Down_Left_MD Arrow_Up_Left_MD Arrow_Up_Right_MD Arrow_Down_Right_MD Shrink Expand Unfold_Less Unfold_More',
  'Arrow_Sub_Right_Down Arrow_Sub_Right_Up Arrow_Sub_Left_Down Arrow_Sub_Left_Up Arrow_Sub_Down_Right Arrow_Sub_Up_Right Arrow_Sub_Down_Left Arrow_Sub_Up_Left Arrow_Undo_Up_Left Arrow_Undo_Up_Right Arrow_Undo_Down_Left Arrow_Undo_Down_Right Arrow_Down_SM Arrow_Up_SM Arrow_Left_SM Arrow_Right_SM Arrow_Down_Left_SM Arrow_Up_Left_SM Arrow_Up_Right_SM Arrow_Down_Right_SM Chevron_Down_Duo Chevron_Up_Duo Chevron_Left_Duo Chevron_Right_Duo']),
 'files': ([91,445.5,799.5],279.5,63.58,24,[
  'Cloud Cloud_Close Cloud_Remove File_Check File_Upload File_Code File_Edit Note_Search Folder Folder_Close Folder_Remove Folder_Document Folders',
  'Cloud_Off Cloud_Download Cloud_Add File_Close File_Remove File_Document Files Notebook Folder_Open Folder_Download Folder_Add Folder_Search Archive',
  'Cloud_Check Cloud_Upload File_Blank File_Download File_Add File_Search Note_Edit Note Folder_Check Folder_Upload Folder_Code Folder_Edit Download_Package']),
 'interface': ([84.5,438.5,792.5],129,63.55,24,[
  'External_Link Check Check_All_Big Link_Break Log_Out Settings_Future Slider_01 Radio_Unchecked Drag_Vertical Option Dummy_Square Dummy_Circle_Small Chart_Bar_Vertical_01 Handbag Instance Checkbox_Fill Credit_Card_01 Line_Xl Line_S Bookmark Magnifying_Glass_Plus Book Trending_Down Shopping_Cart_01 Main_Component',
  'Link_Horizontal_Off Check_All Link Download Exit Settings Slider_02 Checkbox_Unchecked Drag_Horizontal Search_Magnifying_Glass Dummy_Circle Heart_01 Chart_Bar_Horizontal_01 Shopping_Bag_01 Trash_Empty Radio_Fill Credit_Card_02 Line_L Gift Switch_Left Filter Book_Open Trending_Up Shopping_Cart_02',
  'Link_Horizontal Check_Big Link_Vertical Star Ticket_Voucher Command Slider_03 Checkbox_Check Label Magnifying_Glass_Minus Dummy_Square_Small Heart_02 Chart_Line Shopping_Bag_02 Trash_Full Loading Tag Line_M Suitcase Switch_Right Filter_Off Chart_Pie Lock Lock_Open']),
 'calendar': ([103.5,457.5,811.5],305.5,63.5,24,[
  'Calendar Calendar_Remove Calendar_Event Alarm Timer_Add',
  'Calendar_Check Calendar_Week Calendar_Days Timer Timer_Close',
  'Calendar_Add Calendar_Close Clock Timer_Remove']),
 'navigation': ([169.5,523.5,877.5],288.5,63.6,24,[
  'Compass House_03 House_01 House_Check Building_03 Building_04',
  'Globe House_Remove House_02 Building_01 Flag Car_Auto',
  'Map_Pin House_Add House_Close Building_02 Navigation Map']),
 'edit': ([108.5,462.5,816.5],269.5,63.59,24,[
  'Add_To_Queue Layers Text_Align_Center List_Remove List_Unordered Sort_Descending Remove_Minus_Circle Add_Minus_Square Hide Move_Horizontal Paperclip_Attachment_Horizontal Heading Heading_H3 Heading_H6 Text Table Combine_Cells Double_Quotes_R Delete_Column Single_Quotes_L Copy Columns Edit_Pencil_01 Path',
  'Select_Multiple Text_Align_Left Text_Align_Justify List_Ordered List_Checklist Remove_Minus Add_Plus_Circle Add_Plus_Square Show Move_Vertical Paperclip_Attachment_Tilt Heading_H1 Heading_H4 Font Redo Table_Add Bold Double_Quotes_L Add_Row Single_Quotes_R Italic Ruler Edit_Pencil_02 Swatches_Palette',
  'Layer Text_Align_Right List_Check List_Add Sort_Ascending Add_Plus Close_Circle Close_Square Move Mention Figma Heading_H2 Heading_H5 Strikethrough Undo Table_Remove Underline Delete_Row Add_Column Paragraph Rows Edit_Pencil_Line_02 Edit_Pencil_Line_01 Crop']),
 'communication': ([114.5,533.5,952],406,75.125,28,[
  'Chat_Circle Chat_Circle_Dots Chat Chat_Dots Chat_Conversation_Circle Phone Mail Bell_Ring Bell_Remove',
  'Chat_Circle_Close Chat_Circle_Remove Chat_Close Chat_Remove Chat_Conversation Share_Android Mail_Open Bell Bell_Add',
  'Chat_Circle_Check Chat_Circle_Add Chat_Check Chat_Add Paper_Plane Share_iOS_Export Bell_Notification Bell_Off Bell_Close']),
 'environment': ([90.5,509.5,928],356,75,28,[
  'Puzzle Sun Bulb Planet Leaf',
  'First_Aid Moon Cookie Water_Drop',
  'Cupcake Rainbow Coffee_To_Go Coffee']),
 'media': ([112.5,531.5,950],285,75.1,28,[
  'Airplay Skip_Back Play_Circle Play Rewind Shuffle Volume_Minus Volume_Off_02',
  'Chromecast Skip_Forward Stop_Circle Pause Forward Volume_Max Volume_Plus',
  'Pause_Circle Headphones Stop Image_01 Image_02 Volume_Min Volume_Off']),
 'system': ([44.5,463.5,882],294.5,75.09,28,[
  'Mobile_Button Devices Monitor Window Desktop_Tower Bar_Right Save Wifi_Medium Wifi_Off Keyboard Data Window_Terminal',
  'Tablet Laptop Monitor_Play Window_Check Bar_Bottom Window_Sidebar Qr_Code Wifi_Low Wifi_Problem Mouse Camera Window_Code_Block',
  'Tablet_Button Mobile Desktop Window_Close Bar_Left Bar_Top Cylinder Wifi_None Wifi_High Printer Moving_Desk Terminal']),
 'user': ([100.5,519.5,938.5],326.5,75,28,[
  'User_01 User_02 Users User_Voice User_Card_ID',
  'User_Add User_03 Users_Group User_Circle',
  'User_Close User_Remove User_Check User_Square']),
 'shape': ([90.5,509.5,928.5],307,75,28,[
  'Wavy Shield', 'Octagon Triangle', 'Circle Square']),
 'menu': ([92.5,511.5,930.5],307,75,28,[
  'Close_LG Hamburger_MD Menu_Duo_LG Menu_Alt_04 More_Horizontal More_Grid_Big',
  'Close_MD Hamburger_LG Menu_Alt_02 Menu_Alt_05 More_Vertical',
  'Close_SM Menu_Duo_MD Menu_Alt_03 Menu_Alt_01 More_Grid_Small']),
}


def transparent(crop):
    """Recover screenshot alpha; white shape pixels stay on their native grid."""
    corners = [crop.getpixel(p) for p in [(0,0),(crop.width-1,0),(0,crop.height-1),(crop.width-1,crop.height-1)]]
    bg = tuple(sorted(c[i] for c in corners)[len(corners)//2] for i in range(3))
    d = tuple(255-c for c in bg)
    norm = sum(v*v for v in d)
    output = Image.new('RGBA',crop.size)
    values=[]
    max_error=0
    for color in (crop.getpixel((x,y)) for y in range(crop.height) for x in range(crop.width)):
        alpha=max(0,min(255,round(255*sum((color[i]-bg[i])*d[i] for i in range(3))/norm)))
        values.append((255,255,255,alpha))
        max_error=max(max_error,max(abs(round(bg[i]+(255-bg[i])*alpha/255)-color[i]) for i in range(3)))
    output.putdata(values)
    return output,bg,max_error


def main():
    manifest=[]
    for category,(xs,first,pitch,slot,columns) in SHEETS.items():
        source=BASE/'source_sheets'/f'{category}.png'
        image=Image.open(source).convert('RGB')
        destination=BASE/category
        destination.mkdir(parents=True,exist_ok=True)
        entries=[]
        for col,labels in enumerate(columns):
            for row,label in enumerate(labels.split()):
                cx,cy=xs[col],first+row*pitch
                entries.append((col,row,label,cx,cy))
        # One consistent canvas per sheet: original nominal slot plus margins.
        side=slot+2
        while True:
            results=[]
            for col,row,label,cx,cy in entries:
                left,top=round(cx-side/2),round(cy-side/2)
                assert 0 <= left and 0 <= top and left+side <= image.width and top+side <= image.height
                crop=image.crop((left,top,left+side,top+side))
                rgba,bg,error=transparent(crop)
                bbox=rgba.getbbox()
                assert bbox is not None,(category,label,'empty icon')
                results.append((col,row,label,left,top,rgba,bg,error,bbox))
            if all(b[0]>0 and b[1]>0 and b[2]<side and b[3]<side for *_,b in results):break
            side+=2
            assert side<=slot+10,(category,'unexpected clipping/label in crop')
        for col,row,label,left,top,rgba,bg,error,bbox in results:
            assert error<=2,(category,label,'non-monochrome pixels',error)
            asset=destination/(label.lower().replace('_','-')+'.png')
            rgba.save(asset)
            manifest.append(dict(asset=str(asset.relative_to(ROOT)),source=str(source.relative_to(ROOT)),
                label=label,column=col+1,row=row+1,rect=[left,top,side,side],
                background=list(bg),max_composite_error=error))
        print(f'{category}: {len(entries)} icons, {side}x{side} native-pixel crops')
    assert len({entry['asset'] for entry in manifest}) == len(manifest), 'Duplicate icon names'
    (ROOT/'tool/supplemental_icons.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print(f'Total: {len(manifest)} icons. No resizing, tracing, or redrawing.')

if __name__=='__main__':main()
