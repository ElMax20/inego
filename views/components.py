import customtkinter as ctk
from PIL import ImageTk
from config import (
    COLOR_BG_MAIN, COLOR_BG_CARD, COLOR_PRIMARY, COLOR_PRIMARY_HOVER,
    COLOR_ACCENT, COLOR_ACCENT_HOVER, COLOR_LIGHT_BLUE, COLOR_TEXT_PRIMARY,
    COLOR_TEXT_SECONDARY, COLOR_TEXT_MUTED, COLOR_BORDER, COLOR_SUCCESS,
    COLOR_WARNING, COLOR_DANGER, COMPANY_NAME, COMPANY_SLOGAN
)
from utils.assets import generate_tree_of_life_image

class HeaderFrame(ctk.CTkFrame):
    def __init__(self, master, title="SISTEMA DE GESTIÓN CORPORATIVA", **kwargs):
        super().__init__(master, fg_color=COLOR_BG_CARD, corner_radius=0, height=70, **kwargs)
        self.pack_propagate(False)

        left_box = ctk.CTkFrame(self, fg_color="transparent")
        left_box.pack(side="left", padx=20, pady=10)

        pil_img = generate_tree_of_life_image(48, 48)
        self.logo_img = ctk.CTkImage(light_image=pil_img, dark_image=pil_img, size=(48, 48))

        logo_lbl = ctk.CTkLabel(left_box, image=self.logo_img, text="")
        logo_lbl.pack(side="left", padx=(0, 12))

        title_box = ctk.CTkFrame(left_box, fg_color="transparent")
        title_box.pack(side="left")

        comp_lbl = ctk.CTkLabel(
            title_box, text=COMPANY_NAME.upper(),
            font=ctk.CTkFont(family="Segoe UI", size=18, weight="bold"),
            text_color=COLOR_TEXT_PRIMARY
        )
        comp_lbl.pack(anchor="w")

        sub_lbl = ctk.CTkLabel(
            title_box, text=COMPANY_SLOGAN,
            font=ctk.CTkFont(family="Segoe UI", size=11),
            text_color=COLOR_TEXT_SECONDARY
        )
        sub_lbl.pack(anchor="w")

        # Contenedor derecho: Módulo actual y Badge de usuario activo
        right_box = ctk.CTkFrame(self, fg_color="transparent")
        right_box.pack(side="right", padx=20, pady=10)

        self.mod_title_lbl = ctk.CTkLabel(
            right_box, text=title,
            font=ctk.CTkFont(family="Segoe UI", size=14, weight="bold"),
            text_color=COLOR_ACCENT
        )
        self.mod_title_lbl.pack(anchor="e")

        self.user_lbl = ctk.CTkLabel(
            right_box, text="👤 Usuario: Invitado | Rol: Administrador",
            font=ctk.CTkFont(family="Segoe UI", size=11, weight="bold"),
            text_color=COLOR_LIGHT_BLUE
        )
        self.user_lbl.pack(anchor="e")

    def update_module_title(self, new_title):
        self.mod_title_lbl.configure(text=new_title)

    def set_user_info(self, nombre_completo, rol):
        self.user_lbl.configure(text=f"👤 {nombre_completo} | Rol: {rol}")


class MetricCard(ctk.CTkFrame):
    def __init__(self, master, title, value, icon="📊", subtext="", accent_color=COLOR_ACCENT, **kwargs):
        super().__init__(master, fg_color=COLOR_BG_CARD, corner_radius=12, border_width=1, border_color=COLOR_BORDER, **kwargs)

        padding_frame = ctk.CTkFrame(self, fg_color="transparent")
        padding_frame.pack(fill="both", expand=True, padx=16, pady=14)

        top_row = ctk.CTkFrame(padding_frame, fg_color="transparent")
        top_row.pack(fill="x")

        lbl_title = ctk.CTkLabel(
            top_row, text=title.upper(),
            font=ctk.CTkFont(family="Segoe UI", size=11, weight="bold"),
            text_color=COLOR_TEXT_MUTED
        )
        lbl_title.pack(side="left")

        lbl_icon = ctk.CTkLabel(
            top_row, text=icon,
            font=ctk.CTkFont(size=18), text_color=accent_color
        )
        lbl_icon.pack(side="right")

        self.lbl_value = ctk.CTkLabel(
            padding_frame, text=value,
            font=ctk.CTkFont(family="Segoe UI", size=24, weight="bold"),
            text_color=COLOR_TEXT_PRIMARY
        )
        self.lbl_value.pack(anchor="w", pady=(8, 2))

        if subtext:
            lbl_sub = ctk.CTkLabel(
                padding_frame, text=subtext,
                font=ctk.CTkFont(family="Segoe UI", size=11),
                text_color=accent_color
            )
            lbl_sub.pack(anchor="w")

    def set_value(self, new_val):
        self.lbl_value.configure(text=new_val)


class PrimaryButton(ctk.CTkButton):
    def __init__(self, master, text, command=None, icon=None, **kwargs):
        full_text = f"{icon} {text}" if icon else text
        btn_height = kwargs.pop("height", 36)
        super().__init__(
            master, text=full_text, command=command,
            fg_color=COLOR_PRIMARY, hover_color=COLOR_PRIMARY_HOVER,
            text_color=COLOR_TEXT_PRIMARY, corner_radius=8,
            font=ctk.CTkFont(family="Segoe UI", size=12, weight="bold"),
            height=btn_height, **kwargs
        )


class AccentButton(ctk.CTkButton):
    def __init__(self, master, text, command=None, icon=None, **kwargs):
        full_text = f"{icon} {text}" if icon else text
        btn_height = kwargs.pop("height", 36)
        super().__init__(
            master, text=full_text, command=command,
            fg_color=COLOR_ACCENT, hover_color=COLOR_ACCENT_HOVER,
            text_color=COLOR_TEXT_PRIMARY, corner_radius=8,
            font=ctk.CTkFont(family="Segoe UI", size=12, weight="bold"),
            height=btn_height, **kwargs
        )
