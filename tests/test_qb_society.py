r"""
     _                       _____           _       _
    | |                     / ____|         (_)     | |      
    | |    _   _ _ __ ___  | (___   ___ _ __ _ _ __ | |_ ___ 
    | |   | | | | '__/ _ \  \___ \ / __| '__| | '_ \| __/ __|
    | |___| |_| | | |  __/  ____) | (__| |  | | |_) | |_\__ \
    |______\__, |_|  \___| |_____/ \___|_|  |_| .__/ \__|___/
            __/ |                             | |            
           |___/                              |_|

"""

"""QB society accounts resolve to the resource exposing financial exports."""

from lua_test_support import LuaTestCase


class QbSocietyTests(LuaTestCase):
    def setUp(self):
        super().setUp()
        self.run_lua("""
        balance=100
        exports['qb-banking']={
            GetAccountBalance=function(_,job) accountJob=job; return balance end,
            AddMoney=function(_,job,amount) balance=balance+amount; return true end,
            RemoveMoney=function(_,job,amount)
                if balance<amount then return false end
                balance=balance-amount; return true
            end,
        }
        exports['qb-management']=setmetatable({}, {__index=function() error('management has no banking exports') end})
        """)
        self.p = self.provider("server", "society", "qb")

    def test_management_alone_is_not_selected_as_a_financial_provider(self):
        self.g.activeResources["qb-management"] = True
        self.assertFalse(self.p.detect(self.p))

    def test_banking_is_detected_and_controls_the_balance(self):
        self.g.activeResources["qb-banking"] = True
        self.assertTrue(self.p.detect(self.p))
        self.assertEqual(self.p.getMoney(self.p, "police"), 100)
        self.assertEqual(self.g.accountJob, "police")
        self.assertTrue(self.p.addMoney(self.p, "police", 20))
        self.assertTrue(self.p.removeMoney(self.p, "police", 30))
        self.assertEqual(self.p.getMoney(self.p, "police"), 90)

    def test_failed_debit_stays_false_and_does_not_change_money(self):
        self.assertFalse(self.p.removeMoney(self.p, "police", 101))
        self.assertEqual(self.g.balance, 100)
