//
//  ToDoListViewController.swift
//  Todoey
//
//  Created by Philipp Muellauer on 02/12/2019.
//  Copyright © 2019 App Brewery. All rights reserved.
//

import UIKit
//import CoreData
import RealmSwift
import ChameleonFramework

class ToDoListViewController: SwipeTableViewController {
    
    // CoreData: CRUD - CREATE, READ, UPDATE, DESTROY
    
    let realm = try! Realm()
    
//    var itemArray = [Item]()
    var toDoItems: Results<Item>?
    var selectedCategory: Category? {
        didSet { loadItems() }
    }
    
    @IBOutlet weak var searchBar: UISearchBar!
    
//    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    // adding our own custom Item plist
//    let dataFilePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("Items.plist")
    
    // UI: NavigationBar color, Font colors, etc.
    override func viewWillAppear(_ animated: Bool) {
        if let colorHex = selectedCategory?.color {
            title = selectedCategory!.name
            guard let navBar = navigationController?.navigationBar else { fatalError("DNE") }
            if let navBarColor = UIColor(hexString: colorHex) {
                navBar.barTintColor = navBarColor
                navBar.tintColor = ContrastColorOf(navBarColor, returnFlat: true)
                navBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor : ContrastColorOf(navBarColor, returnFlat: true)]
                searchBar.barTintColor = navBarColor
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // where the data is being stored
//        print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
        tableView.separatorStyle = .none
    }
    
    // MARK: - Tableview Datasource Methods
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return toDoItems?.count ?? 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        if let item = toDoItems?[indexPath.row] {
            cell.textLabel?.text = item.title
            cell.accessoryType = item.done ? .checkmark : .none
            // gradient effect - continues gradient theme from category VC to item VC
            if let color = UIColor(hexString: selectedCategory!.color)?.darken(byPercentage: (CGFloat(indexPath.row) / CGFloat(toDoItems!.count))) {
                cell.backgroundColor = color
                // font color based on gradient (darker gradient -> whiter font)
                cell.textLabel?.textColor = ContrastColorOf(color, returnFlat: true)
            }
        } else {
            cell.textLabel?.text = "No Items Added"
        }
        return cell
    }
    
    // MARK: - Tableview Delegate Methods
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        context.delete(   [indexPath.row])
//        itemArray.remove(at: indexPath.row)
//        toDoItems[indexPath.row].done.toggle()
//        saveItems()
        if let item = toDoItems?[indexPath.row] {
            do { try realm.write { item.done = !item.done } }
            catch { print("Error saving done status, \(error)") }
        }
        tableView.reloadData()
        tableView.deselectRow(at: indexPath, animated: true) // turns grey momentarily on touch
    }
    
    // MARK: - Add New Items
    
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        var textField = UITextField()
        let alert = UIAlertController(title: "Add New Todoey Item", message: "", preferredStyle: .alert)
        alert.addTextField { alertTextField in
            alertTextField.placeholder = "Create new item"
            textField = alertTextField // to use in action call, need to hold the text value
        }
        // when user clicks on add item button
        let action = UIAlertAction(title: "Add Item", style: .default) { (action) in
            if let currentCategory = self.selectedCategory {
                do {
                    try self.realm.write {
                        let newItem = Item()
                        newItem.title = textField.text!
                        newItem.dateCreated = Date()
                        currentCategory.items.append(newItem)
                    }
                } catch {
                    print("Error saving new items, \(error)")
                }
            }
            self.tableView.reloadData()
        }
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Model Manipulation Methods
    
    /*
    // '=' allows for default value. 'with' is the external parameter for more readability
    func loadItems(with request: NSFetchRequest<Item> = Item.fetchRequest(), predicate: NSPredicate? = nil) {
        let categoryPredicate = NSPredicate(format: "parentCategory.name MATCHES %@", selectedCategory!.name!)
        if let additionalPredicate = predicate {
            // filter items that match both predicates
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [categoryPredicate, additionalPredicate])
        } else {
            request.predicate = categoryPredicate
        }
//        if let data = try? Data(contentsOf: dataFilePath!) {
//            let decoder = PropertyListDecoder()
//            do { itemArray = try decoder.decode([Item].self, from: data) }
//             catch { print(error) }
//        }
        do { itemArray = try context.fetch(request) }
        catch { print("error fetching data from context \(error)") }
        tableView.reloadData()
    }
     */
    
    // new method using Realm - makes things more simplified
    func loadItems() {
        toDoItems = selectedCategory?.items.sorted(byKeyPath: "title", ascending: true)
        tableView.reloadData()
    }
    
    override func updateModel(at indexPath: IndexPath) {
        if let item = toDoItems?[indexPath.row] {
            do { try realm.write { realm.delete(item) } }
            catch { print("Error deleting item, \(error)") }
        }
     }
    
}

    // MARK: - Search bar methods

extension ToDoListViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        /** Using Core Data */
//        let request: NSFetchRequest<Item> = Item.fetchRequest()
//        // [cd] - case and diacritic insensitive (diacritic - small mark added to letters to alter pronounciation)
//        let predicate = NSPredicate(format: "title CONTAINS[cd] %@", searchBar.text!)
//        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
//        loadItems(with: request, predicate: predicate)
        
        /** Using Realm */
        toDoItems = toDoItems?.filter("Title CONTAINS[cd] %@", searchBar.text!).sorted(byKeyPath: "dateCreated", ascending: true)
        tableView.reloadData()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // clearing the search text resets the view
        if searchBar.text?.count == 0 {
            loadItems()
            DispatchQueue.main.async{ searchBar.resignFirstResponder() }
        }
    }
    
}

