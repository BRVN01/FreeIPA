#!/usr/bin/env python3

import cgitb
import cgi
import sys
import ldap

class idmAccess:

    def __init__(self):
        self.server = 'ldaps://idm.maddogs.br'
        self.user_dn = ',cn=users,cn=accounts,dc=maddogs,dc=br'
        self.init_html()

    def init_html(self):
        cgitb.enable(display=1, logdir="/tmp/")

        print("""
        <html>
        <head>
            <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
        <style>
        body {
          background-color: #9c9b8f;
        }
        .container {
          width: 50%;
          margin: 0 auto;
          text-align: center;
          border: 2px solid #000;
          padding: 20px;
        }
        .logo {
          width: 100px;
          height: 100px;
          margin: 0 auto;
          background-image: url("URL");
          background-repeat: no-repeat;
          background-size: contain;
        }
        form {
          display: flex;
          flex-direction: column;
          justify-content: center;
          align-items: center;
          height: 30vh;
        }
        input[name="oldpassword"] {
          margin-top: 10px;
        }
        input[name="name"] {
          margin-top: 10px;
        }
        input[name="newpassword"] {
          margin-top: 10px;
        }
        input[name="repeaternewpassword"] {
          margin-top: 10px;
        }
        label {
          margin-top: 20px;
        }
        </style>
        </head>
        <body>
        <div class="container">
        <div class="logo"></div>
        <form enctype="multipart/form-data" method="post">
        <label>Nome:<label> <input type="text" name="name">\n
        <BR><BR>
        <label>Senha atual:</label> <input type="password" name="oldpassword">
        <BR><BR>
        <label>Nova senha:<label> <input type="password" name="newpassword">\n
        <BR><BR>
        <label>Repita a nova senha:</label> <input type="password" name="repeaternewpassword">
        <input type="submit" value="Enviar" name="Enviar">
        </form>
        </div>
        </body>
        </html>""")

        form = cgi.FieldStorage()

        if ("name" in form) and ("oldpassword" in form):
            self.name = form["name"].value
            self.oldpassword = form["oldpassword"].value      
        else:
            sys.exit(1)

        if ("newpassword" in form) and ("repeaternewpassword" in form):
            newpassword = form["newpassword"].value
            repeaternewpassword = form["repeaternewpassword"].value

        if (newpassword == repeaternewpassword):
            self.newpassword = newpassword        
            self.ldaptest()
        else:
            self.print_html_message("As senhas não correspondem.")

        # print('nome:', self.name)
        # print('Senha atual:', self.oldpassword)


    def clear_screen(self):
        print("""
            <html>
                <head>
                    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
                    <title>Clear Screen</title>
                </head>
                <body>
                    <script>
                        document.body.innerHTML = "";
                    </script>
                </body>
            </html>
        """)

    def print_html_message(self, html_message):
        self.clear_screen()

        print("""
        <html>
        <head>
            <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
        <style>
        body {
          background-color: #9c9b8f;
        }
        .container {
          width: 50%;
          margin: 0 auto;
          text-align: center;
          border: 2px solid #000;
          padding: 20px;
        }
        .logo {
          width: 100px;
          height: 100px;
          margin: 0 auto;
          background-image: url("URL");
          background-repeat: no-repeat;
          background-size: contain;
        }
        form {
          display: flex;
          flex-direction: column;
          justify-content: center;
          align-items: center;
          height: 30vh;
        }
        input[name="Reset"] {
          margin-top: 10px;
        }
        label {
          margin-top: 20px;
        }
        </style>
        </head>
        <body>
        <div class="container">
        <div class="logo"></div>
        <form enctype="multipart/form-data" method="post">""")
        print("<label> {0} </label>".format(html_message))
        print("""
        <BR><BR>
        <input type="submit" value="Reset" name="Reset">
        </form>
        </div>
        </body>
        </html>""")

    def ldaptest(self):
        # Conectar ao servidor LDAP

        try:
            conn = ldap.initialize(self.server)
            conn.simple_bind_s('uid=' + self.name + self.user_dn, self.oldpassword)
            #self.print_html_message('Conexão LDAP bem-sucedida!')
            self.ldappassword()

        except ldap.INVALID_CREDENTIALS:
            self.print_html_message('Credenciais inválidas')
            sys.exit(10)

        except ldap.SERVER_DOWN:
            self.print_html_message('Servidor LDAP inacessível')
            sys.exit(1)

        except ldap.LDAPError as ldaperror:
            self.print_html_message(ldaperror)
            sys.exit(1)

        finally:
            conn.unbind()

    def ldappassword(self):
        try:
            conn = ldap.initialize(self.server)
            conn.simple_bind_s('uid=' + self.name + self.user_dn, self.oldpassword)

            ldif = [(ldap.MOD_REPLACE, 'userPassword', self.newpassword.encode('utf-8'))]
            conn.modify_s('uid=' + self.name + self.user_dn, ldif)
            self.print_html_message('Senha do usuário alterada com sucesso!')

        except ldap.SERVER_DOWN:
           self.print_html_message('Servidor LDAP inacessível')
           sys.exit(1)

        except ldap.LDAPError as ldaperror:
            self.print_html_message(ldaperror)
            sys.exit(1)

        finally:
            conn.unbind()

if __name__ == "__main__":
        init_class = idmAccess()
