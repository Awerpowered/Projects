import mysql.connector
import random
from datetime import datetime
import tkinter as tk
from tkinter import ttk, messagebox


# ========== KONFIGURACJA BAZY I FUNKCJE POMOCNICZE ==========
def get_db_connection():
    return mysql.connector.connect(**dbconfig)


def execute_query(query, params=None, fetch_one=False):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(query, params or ())
        result = cursor.fetchone() if fetch_one else cursor.fetchall()
        conn.commit()
        return result
    except Exception as e:
        messagebox.showerror("Database Error", str(e))
        conn.rollback()
    finally:
        cursor.close()
        conn.close()


def call_procedure(procedure_name, params=None):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        if params:
            placeholders = ', '.join(['%s'] * len(params)) + ', @output_id'
            query = f"CALL {procedure_name}({placeholders})"
            cursor.execute(query, params)
            cursor.execute("SELECT @output_id")
            wynik = cursor.fetchone()[0]
        else:
            cursor.callproc(procedure_name)
            for result in cursor.stored_results():
                wynik = result.fetchone()[0]
                break
        conn.commit()
        return wynik if wynik != -1 else None
    except Exception as e:
        messagebox.showerror("Procedure error", str(e))
        return None
    finally:
        cursor.close()
        conn.close()


def losuj_czas_trwania():
    return random.randint(0, 20) if random.random() < 0.7 else random.randint(21, 500)


dbconfig = {
    'host': "127.0.0.1",
    'user': "", #your username to database
    'password': "", #your password to database
    'database': "TEST1",
    'charset': "utf8mb4",
    'collation': "utf8mb4_general_ci"
}

wojewodztwa = {
    1: 'Mazowieckie',
    2: 'Śląskie',
    3: 'Wielkopolskie',
    4: 'Małopolskie',
    5: 'Dolnośląskie',
    6: 'Łódzkie',
    7: 'Pomorskie',
    8: 'Kujawsko-Pomorskie',
    9: 'Podkarpackie',
    10: 'Zachodniopomorskie'
}


# ========== GUI ==========
class Application(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("Campaign Management System")
        self.geometry("800x600")
        self.current_frame = None
        self.user_data = {'id': None, 'name': None, 'campaign_id': None, 'log_id': None, 'role_id': None}
        self.client_data = {'id': None, 'details': None}
        self.call_data = {'start_time': None, 'sukces': None, 'id_polaczenia': None}
        self.break_start_time = None
        self.czas_przerwy = 0.0
        self.show_login_frame()

    def clear_frame(self):
        if self.current_frame:
            self.current_frame.destroy()
            self.current_frame = None

    def show_login_frame(self):
        self.clear_frame()
        self.current_frame = LoginFrame(self)
        self.current_frame.pack(fill=tk.BOTH, expand=True)

    def show_main_frame(self):
        self.clear_frame()
        self.current_frame = MainFrame(self)
        self.current_frame.pack(fill=tk.BOTH, expand=True)

    def show_manager_view(self, campaign_id):
        self.clear_frame()
        self.current_frame = ManagerFrame(self, campaign_id)
        self.current_frame.pack(fill=tk.BOTH, expand=True)

    def show_lead_frame(self):
        self.clear_frame()
        self.current_frame = LeadFrame(self)
        self.current_frame.pack(fill=tk.BOTH, expand=True)

    def show_refusal_frame(self):
        self.clear_frame()
        self.current_frame = RefusalFrame(self)
        self.current_frame.pack(fill=tk.BOTH, expand=True)

    def logout(self):
        if self.break_start_time:
            self.czas_przerwy += (datetime.now() - self.break_start_time).total_seconds()

        execute_query(
            "UPDATE LogiDostepu SET czas_przerwy = %s, czas_wylogowania = NOW() WHERE id_logu = %s",
            (self.czas_przerwy, self.user_data['log_id'])
        )

        self.user_data = {'id': None, 'name': None, 'campaign_id': None, 'log_id': None, 'role_id': None}
        self.break_start_time = None
        self.czas_przerwy = 0.0
        self.show_login_frame()


class LoginFrame(ttk.Frame):
    def __init__(self, parent):
        super().__init__(parent)
        self.app = parent

        ttk.Label(self, text="Login Panel", font=('Arial', 14)).pack(pady=20)

        form_frame = ttk.Frame(self)
        form_frame.pack(pady=20)

        ttk.Label(form_frame, text="Username").grid(row=0, column=0, padx=5, pady=5)
        self.username = ttk.Entry(form_frame)
        self.username.grid(row=0, column=1, padx=5, pady=5)

        ttk.Label(form_frame, text="Password").grid(row=1, column=0, padx=5, pady=5)
        self.password = ttk.Entry(form_frame, show="*")
        self.password.grid(row=1, column=1, padx=5, pady=5)

        ttk.Button(self, text="Login", command=self.login).pack(pady=10)

    def login(self):
        result = execute_query(
            "SELECT id_uzytkownika, imie, id_kampanii, id_roli FROM Uzytkownicy WHERE nazwa_uzytkownika = %s AND haslo = %s",
            (self.username.get(), self.password.get()),
            fetch_one=True
        )

        if result:
            user_id, name, campaign_id, role_id = result
            conn = get_db_connection()
            cursor = conn.cursor()
            cursor.execute(
                "INSERT INTO LogiDostepu (czas_logowania, id_uzytkownika, id_kampanii) VALUES (NOW(), %s, %s)",
                (user_id, campaign_id)
            )
            log_id = cursor.lastrowid
            conn.commit()
            cursor.close()
            conn.close()

            self.app.user_data = {
                'id': user_id,
                'name': name,
                'campaign_id': campaign_id,
                'log_id': log_id,
                'role_id': role_id
            }

            if role_id == 1:
                self.app.show_manager_view(campaign_id)
            else:
                self.app.show_main_frame()
        else:
            messagebox.showerror("Error", "Invalid login credentials!")


class ManagerFrame(ttk.Frame):
    def __init__(self, parent, campaign_id):
        super().__init__(parent)
        self.app = parent
        self.campaign_id = campaign_id
        self.create_widgets()

    def create_widgets(self):
        self.button_frame = ttk.Frame(self)
        self.button_frame.pack(pady=20)

        ttk.Button(self.button_frame,
                   text="Total Leads",
                   command=self.show_leads).grid(row=0, column=0, padx=10)

        ttk.Button(self.button_frame,
                   text="Marketing Campaign ",
                   command=self.show_campaign).grid(row=0, column=1, padx=10)

        self.tree = ttk.Treeview(self, columns=("Użytkownik", "Połączenia", "Czas", "Sukcesy"), show="headings")
        self.tree.heading("Użytkownik", text="Użytkownik")
        self.tree.heading("Połączenia", text="Połączenia")
        self.tree.heading("Czas", text="Czas rozmów")
        self.tree.heading("Sukcesy", text="Sukcesy")
        self.tree.pack(expand=True, fill='both')

        logout_frame = ttk.Frame(self)
        logout_frame.pack(side=tk.BOTTOM, pady=20)
        ttk.Button(logout_frame, text="Log out", command=self.app.logout).pack(side=tk.LEFT, padx=5)

    def show_leads(self):
        for i in self.tree.get_children():
            self.tree.delete(i)

        results = execute_query(
            "SELECT uzytkownik, liczba_polaczen, laczny_czas_rozmow, sukcesy "
            "FROM Widok_Aktywnosci_Uzytkownikow "
            "WHERE id_kampanii = %s "
            "ORDER BY sukcesy DESC",
            (self.campaign_id,)
        )

        for row in results:
            self.tree.insert("", "end", values=row)

    def show_campaign(self):
        for i in self.tree.get_children():
            self.tree.delete(i)

        results = execute_query(
            "SELECT nazwa_kampanii, liczba_polaczen, sredni_czas_rozmowy, sukcesy, srednia_ocena_ankiety "
            "FROM Widok_Efektywnosci_Kampanii"
        )

        for row in results:
            self.tree.insert("", "end", values=row)


class MainFrame(ttk.Frame):
    def __init__(self, parent):
        super().__init__(parent)
        self.app = parent
        self.duration = 0
        self.create_widgets()
        self.initialize_call()

    def initialize_call(self):
        self.duration = losuj_czas_trwania()
        self.app.call_data['start_time'] = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        self.app.client_data['id'] = call_procedure("WylosujKlienta")

        if self.app.client_data['id']:
            self.app.client_data['details'] = execute_query(
                "SELECT imie, nazwisko, numer_telefonu FROM Klienci WHERE id_klienta = %s",
                (self.app.client_data['id'],),
                fetch_one=True
            )

        conn = get_db_connection()
        cursor = conn.cursor()
        try:
            cursor.execute(
                "INSERT INTO Polaczenia (id_uzytkownika, id_klienta, id_kampanii, data_polaczenia, czas_trwania) VALUES (%s, %s, %s, %s, %s)",
                (
                    self.app.user_data['id'],
                    self.app.client_data['id'],
                    self.app.user_data['campaign_id'],
                    self.app.call_data['start_time'],
                    self.duration
                )
            )
            self.app.call_data['id_polaczenia'] = cursor.lastrowid
            conn.commit()
        except Exception as e:
            messagebox.showerror("Database error", str(e))
            conn.rollback()
        finally:
            cursor.close()
            conn.close()

        self.update_client_info()

    def update_client_info(self):
        self.duration_label.config(text=f"Connection time: {self.duration} seconds")
        if self.app.client_data['details']:
            client_info = f"Client: {self.app.client_data['details'][0]} {self.app.client_data['details'][1]}\nPhone number: {self.app.client_data['details'][2]}"
            self.client_info_label.config(text=client_info)
        else:
            self.client_info_label.config(text="No client data!")

    def create_widgets(self):
        ttk.Label(self, text=f"Welcome {self.app.user_data['name']}!", font=('Arial', 14)).pack(pady=10)

        self.info_frame = ttk.LabelFrame(self, text="Connection details")
        self.info_frame.pack(pady=10, padx=20, fill=tk.X)

        self.duration_label = ttk.Label(self.info_frame, text="")
        self.duration_label.pack(pady=5)

        self.client_info_label = ttk.Label(self.info_frame, text="")
        self.client_info_label.pack(pady=5)

        self.action_frame = ttk.Frame(self)
        self.action_frame.pack(pady=20)

        ttk.Button(self.action_frame, text="Lead", command=self.handle_lead).grid(row=0, column=0, padx=10)
        ttk.Button(self.action_frame, text="Denial", command=self.handle_refusal).grid(row=0, column=1, padx=10)

        logout_frame = ttk.Frame(self)
        logout_frame.pack(side=tk.BOTTOM, pady=20)

        self.break_button = ttk.Button(logout_frame, text="Break", command=self.toggle_break)
        self.break_button.pack(side=tk.LEFT, padx=5)
        ttk.Button(logout_frame, text="Log out", command=self.app.logout).pack(side=tk.LEFT, padx=5)

    def toggle_break(self):
        if self.app.break_start_time is None:
            self.app.break_start_time = datetime.now()
            self.break_button.config(text="Resume work")
            self.action_frame.pack_forget()
            self.info_frame.pack_forget()
            self.duration_label.config(text="Break in progress..")
        else:
            self.app.czas_przerwy += (datetime.now() - self.app.break_start_time).total_seconds()
            self.app.break_start_time = None
            self.break_button.config(text="Break")
            self.action_frame.pack(pady=20)
            self.info_frame.pack(pady=10, padx=20, fill=tk.X)
            self.initialize_call()

    def handle_lead(self):
        self.app.call_data['sukces'] = 1
        self.app.show_lead_frame()

    def handle_refusal(self):
        self.app.call_data['sukces'] = 0
        self.app.show_refusal_frame()


class LeadFrame(ttk.Frame):
    def __init__(self, parent):
        super().__init__(parent)
        self.app = parent
        self.entries = {}
        self.create_widgets()

    def create_widgets(self):
        notebook = ttk.Notebook(self)
        notebook.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)

        self.create_technical_tab(notebook)
        self.create_address_tab(notebook)

        ttk.Button(self, text="Save", command=self.save_data).pack(pady=10)

    def create_technical_tab(self, notebook):
        tech_frame = ttk.Frame(notebook)
        notebook.add(tech_frame, text="Technical specifications")

        options = {
            'Windows': ['Drewniane', 'Plastikowe'],
            'wall insulation': ['styropian', 'niestandardowe', 'brak'],
            'roof insulation': ['styropian', 'wełna', 'brak'],
            'Heating': ['Pompa Ciepła', 'Gazowe', 'Piec olejowy', 'Piec 5 klasy', 'Piec 4 klasy lub niżej']
        }

        for i, (key, values) in enumerate(options.items()):
            frame = ttk.Frame(tech_frame)
            frame.grid(row=i, column=0, sticky=tk.W, padx=10, pady=5)
            ttk.Label(frame, text=f"{key.replace('_', ' ').title()}:").pack(side=tk.LEFT)
            var = tk.StringVar(value=values[0])
            for val in values:
                rb = ttk.Radiobutton(frame, text=val, variable=var, value=val)
                rb.pack(side=tk.LEFT, padx=5)
            self.entries[key] = var

    def create_address_tab(self, notebook):
        addr_frame = ttk.Frame(notebook)
        notebook.add(addr_frame, text="Address data")

        fields = [
            ('ulica', 'Street:'),
            ('numer_domu', 'House number:'),
            ('numer_mieszkania', 'Flat number:'),
            ('miasto', 'City:'),
            ('kod_pocztowy', 'Postal code:')
        ]

        for i, (key, label) in enumerate(fields):
            frame = ttk.Frame(addr_frame)
            frame.grid(row=i, column=0, sticky=tk.W, padx=10, pady=5)
            ttk.Label(frame, text=label).pack(side=tk.LEFT)
            entry = ttk.Entry(frame)
            entry.pack(side=tk.LEFT, padx=5)
            self.entries[key] = entry

        ttk.Label(addr_frame, text="Voivodeship:").grid(row=5, column=0, sticky=tk.W, padx=10, pady=5)
        self.woj_var = tk.StringVar()
        woj_combo = ttk.Combobox(addr_frame, textvariable=self.woj_var, values=list(wojewodztwa.values()))
        woj_combo.grid(row=6, column=0, sticky=tk.W, padx=10, pady=5)

    def save_data(self):
        try:
            id_izolacji = call_procedure("PobierzIdIzolacji", [
                self.entries['ocieplenie_dachu'].get(),
                self.entries['ocieplenie_scian'].get(),
                self.entries['okna'].get()
            ])

            execute_query(
                "INSERT INTO Adresy (ulica, numer_domu, numer_mieszkania, miasto, kod_pocztowy, id_wojewodztwa, id_klienta) VALUES (%s, %s, %s, %s, %s, %s, %s)",
                (
                    self.entries['ulica'].get(),
                    self.entries['numer_domu'].get(),
                    self.entries['numer_mieszkania'].get() or None,
                    self.entries['miasto'].get(),
                    self.entries['kod_pocztowy'].get(),
                    [k for k, v in wojewodztwa.items() if v == self.woj_var.get()][0],
                    self.app.client_data['id']
                )
            )

            execute_query(
                "UPDATE Polaczenia SET sukces = %s WHERE id_polaczenia = %s",
                (self.app.call_data['sukces'], self.app.call_data['id_polaczenia'])
            )

            heating_mapping = {
                'Pompa Ciepła': 1,
                'Gazowe': 2,
                'Piec olejowy': 3,
                'Piec 5 klasy': 4,
                'Piec 4 klasy lub niżej': 5
            }

            execute_query(
                """UPDATE SzczegolyKlienta 
                SET id_ogrzewania = %s, id_izolacji = %s  
                WHERE id_klienta = %s""",
                (
                    heating_mapping[self.entries['ogrzewanie'].get()],
                    id_izolacji,
                    self.app.client_data['id']
                )
            )

            messagebox.showinfo("Succes!", "Data has been saved!")
            self.app.show_main_frame()
        except Exception as e:
            messagebox.showerror("Error", f"Error occurred during save operation: {str(e)}")


class RefusalFrame(ttk.Frame):
    def __init__(self, parent):
        super().__init__(parent)
        self.app = parent
        self.create_widgets()

    def create_widgets(self):
        ttk.Label(self, text="Select the reason for rejection:", font=('Arial', 12)).pack(pady=10)

        self.reasons_list = tk.Listbox(self)
        obiekcje = execute_query("SELECT id_obiekcji, tresc_obiekcji FROM Obiekcje")
        for _, tresc in obiekcje:
            self.reasons_list.insert(tk.END, tresc)
        self.reasons_list.pack(pady=10, fill=tk.BOTH, expand=True)

        ttk.Button(self, text="Save", command=self.save_refusal).pack(pady=10)

    def save_refusal(self):
        selected = self.reasons_list.curselection()
        if selected:
            try:
                obiekcje = execute_query("SELECT id_obiekcji FROM Obiekcje")
                id_obiekcji = obiekcje[selected[0]][0]

                execute_query(
                    "INSERT INTO ObiekcjeDzialaniaPoPolaczeniu (id_polaczenia, id_uzytkownika, id_obiekcji) VALUES (%s, %s, %s)",
                    (self.app.call_data['id_polaczenia'], self.app.user_data['id'], id_obiekcji)
                )

                execute_query(
                    "UPDATE Polaczenia SET sukces = %s WHERE id_polaczenia = %s",
                    (self.app.call_data['sukces'], self.app.call_data['id_polaczenia'])
                )

                messagebox.showinfo("Sukces", "The refusal has been saved!")
                self.app.show_main_frame()
            except Exception as e:
                messagebox.showerror("Error", f"An error occurred: {str(e)}")
        else:
            messagebox.showwarning("Warning", "Please select the reason for rejection!")


if __name__ == "__main__":
    app = Application()
    app.mainloop()