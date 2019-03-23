import UIKit
import Firebase

class ShoppingTableViewController: UITableViewController {
    
    let collection = "shoppingList"
    
    var firestoreListener: ListenerRegistration!
    var firestore: Firestore = {
        var settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        
        var firestore = Firestore.firestore()
        firestore.settings = settings
        
        return firestore
    }()
    
    var shoppingList: [ShoppingItem] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = Auth.auth().currentUser?.displayName
        
        listItems()
    }

    func listItems(){
        //.whereField("authorID", isEqualTo: Auth.auth().currentUser!.uid).order(by: "quantity", descending: true)
        firestoreListener = firestore.collection(collection).addSnapshotListener(includeMetadataChanges : true){ (snapshot, error) in
            if error != nil {
                print(error!)
            }
            
            guard let snapshot = snapshot else {return}
            print("Total de mudanças: ", snapshot.documentChanges.count)
            
            if snapshot.metadata.isFromCache || snapshot.documentChanges.count > 0 {
                self.showItems(snapshot: snapshot)
            }
        }
    }
    
    func showItems(snapshot: QuerySnapshot){
        shoppingList.removeAll()
        for document in snapshot.documents {
            let data = document.data()
            if let name = data["name"] as? String, let quantity = data["quantity"] as? Int {
                let shoppingItem = ShoppingItem(name: name, quantity: quantity, id: document.documentID)
                shoppingList.append(shoppingItem)
            }
        }
        tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return shoppingList.count
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let shoppingItem = shoppingList[indexPath.row]
        
        cell.textLabel?.text = shoppingItem.name
        cell.detailTextLabel?.text = "\(shoppingItem.quantity)"
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = shoppingList[indexPath.row]
        addEdit(shoppingItem: item)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    @IBAction func add(_ sender: Any) {
        addEdit()
    }
   
    func addEdit(shoppingItem: ShoppingItem? = nil){
        let title = shoppingItem == nil ? "Adicionar" : "Editar"
        let message = shoppingItem == nil ? "adicionado" : "editado"
        let alert = UIAlertController(title: title, message: "Digite abaixo os dados do item a ser \(message)", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "Nome"
            textField.text = shoppingItem?.name
        }
        alert.addTextField { (textField) in
            textField.placeholder = "Quantidade"
            textField.keyboardType = .numberPad
            textField.text = shoppingItem?.quantity.description
        }
        
        let addAction = UIAlertAction(title: title, style: .default) { (_) in
            guard let name = alert.textFields?.first?.text,
                let quantity = alert.textFields?.last?.text,
                !name.isEmpty, !quantity.isEmpty else {return}
            
            var item = shoppingItem ?? ShoppingItem()
            item.name = name
            item.quantity = Int(quantity) ?? 1
            self.addItem(item)
        }
        let cancelAction = UIAlertAction(title: "Cancelar", style: .cancel) { (_) in
        }
        alert.addAction(addAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    
    func addItem(_ item: ShoppingItem){
        let data: [String: Any] = [
            "name": item.name,
            "quantity": item.quantity
        ]
        
        if item.id.isEmpty {
            firestore.collection(collection).addDocument(data: data){
                (error) in
                if error != nil {
                    print(error!)
                }
            }
        } else {
            firestore.collection(collection).document(item.id).updateData(data){
                (error) in
                if error != nil {
                    print(error!)
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let item = shoppingList[indexPath.row]
            firestore.collection(collection).document(item.id).delete()
        }
    }
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
